# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
module Tenejo
  class CsvImporter
    def initialize(import_job)
      @job = import_job
      @depositor = import_job.user.user_key
      @logger = Rails.logger
      if preflight_errors.present?
        @job.status = :errored
        @job.completed_at = Time.current
      else
        @job.status = :submitted
      end
      @job.save
    end

    def csv_import_file_root
      File.join(Hyrax.config.upload_path.call, 'ftp')
    end

    def preflight_errors
      @job.graph&.fatal_errors
    end

    def preflight_warnings
      @job.graph.warnings
    end

    def invalid_rows
      @job.graph.invalids
    end

    def import
      return if fatal_errors(@job.graph)
      @job.status = :in_progress
      @job.save!
      @job.graph.flatten.each do |node|
        create_or_update(node)
        ensure_thumbnails(node)
      end
      flat = @job.graph.flatten
      @job.collections = flat.count { |x| x.is_a? PFCollection }
      @job.works = flat.count { |x| x.is_a? PFWork }
      @job.files = flat.count { |x| x.is_a? PFFile }
      @job.completed_at = Time.current
      @job.status = :completed
      @job.save!
    end

    def create_or_update(node)
      case node
      when Tenejo::PFCollection
        create_or_update_collection(node)
      when Tenejo::PFWork
        create_or_update_work(node)
      when Tenejo::PFFile
      # skip for now
      else
        @job.graph.add_fatal_error("Row: #{node.lineno} - Did not create #{node.class} with identifier #{node.identifier} ")
      end
    end

    def ensure_thumbnails(node)
      return unless node.class == Tenejo::PFWork
      work = Work.where(primary_identifier_ssi: node.identifier.first)&.last
      unless work
        @logger.error "CSV Importer couldn't find Work with primary_id #{node&.identifier} to attach thumbnail"
        return
      end
      return if work&.thumbnail_id && work&.representative_id # bypasses re-saving if there are no changes
      work.thumbnail_id ||= work.ordered_members.to_a.first&.thumbnail_id
      work.representative_id ||= work.ordered_members.to_a.first&.representative_id
      work.save!
    end

    def fatal_errors(graph)
      graph.fatal_errors&.any?
    end

    def job_owner
      @depositor
    end

    def search_members(type, file_id)
      @job.graph.flatten.find { |x| x.is_a?(type) && x.identifier == file_id }
    end

    def update_status(item, start_state, end_state)
      tmp = @job.graph
      member = search_members(item.class, item.identifier)
      if member
        member.status = start_state
        @job.graph = tmp # this only exists to trick ActiveRecord into actually saving the modified graph
        @job.save!
        yield
        member.status = end_state
        @job.graph = tmp # same here
        @job.save!
      else
        yield # still need to call the block if the member doesn't exist in the graph somehow. this seems like a bug related to test setup
      end
    end

    def create_or_update_collection(pfcollection)
      # put all the expensive stuff here
      # and unit test the heck out of it
      update_status(pfcollection, 'started', 'completed') do
        collection = find_or_new_collection(pfcollection.identifier, pfcollection.title)
        update_collection_attributes(collection, pfcollection)
        if pfcollection.parent
          parent = Collection.where(primary_identifier_ssi: pfcollection.parent).first
          collection.member_of_collections << parent if parent
        end
        save_collection(collection)
      end
    end

    # Finds or creates a collection by its user supplied identifier
    # returns a valid collection or nil
    def find_or_new_collection(primary_id, title)
      collection_found = Collection.where(primary_identifier_ssi: primary_id).last
      return collection_found if collection_found
      Collection.new(
        primary_identifier: primary_id.first,
        identifier: primary_id,
        title: title,
        depositor: job_owner,
        collection_type_gid: Tenejo::CsvImporter.default_collection_type.gid
      )
    end

    def update_collection_attributes(collection, pfcollection)
      return unless collection
      Tenejo::CsvImporter.collection_attributes_to_copy.each { |source, dest| collection.send(dest, pfcollection.send(source)) }

      collection.primary_identifier = pfcollection.identifier.first

      # these timestamps are the Hyrax managed fields, not rails timestamps
      update_timestamp(collection)

      collection.depositor ||= job_owner

      # set the collection parent relationship
      update_parent(collection, pfcollection)
    end

    def update_parent(collection, pfcollection)
      return unless pfcollection.parent
      parent = Collection.where(primary_identifier_ssi: pfcollection.parent).first
      return unless parent
      collection.member_of_collections << parent
    end

    def save_collection(collection)
      return unless collection
      begin
        collection.save!
        # update job status table - collection creation successful
      rescue
        # update job status table - collection creation failed - save error to table
      end
    end

    def create_or_update_work(pfwork)
      # expensive stuff here
      update_status(pfwork, 'started', 'completed') do
        work = find_or_new_work(pfwork.identifier, pfwork.title)
        update_work_attributes(work, pfwork)
        create_or_update_files(work, pfwork)
        save_work(work)
      end
    end

    # Finds or creates a work by its user supplied identifier
    # returns a valid work or nil
    def find_or_new_work(primary_id, title)
      work_found = Work.where(primary_identifier_ssi: primary_id).last
      return work_found if work_found
      Work.new(
        primary_identifier: primary_id.first,
        title: title,
        depositor: job_owner,
        admin_set: admin_set_for_work
      )
    end

    def update_work_attributes(work, pfwork)
      return unless work
      Tenejo::CsvImporter.work_attributes_to_copy.each { |source, dest| work.send(dest, pfwork.send(source)) }
      set_work_parent(work, pfwork)
      update_timestamp(work)
      work.admin_set ||= admin_set_for_work
      work.rights_statement = normalized_rights(pfwork.rights_statement)
      work.primary_identifier = pfwork.identifier.first
      work.depositor ||= job_owner
    end

    def normalized_rights(rights_statement)
      rights = rights_statement.first
      # authority.find matches when rights_statement contains an ID (URI)
      matched = rights_statement_authority.find(rights)['id']

      # authority.search matches when rights_statement contains a label
      matched ||= rights_statement_authority.search(rights).first&.fetch('id')

      # otherwise default to copyright not evaluated
      matched ||= copyright_not_evaluated
      [matched]
    end

    # Determine whether to update date_uploaded or date_modified
    # and set the correct one to the current time
    def update_timestamp(work)
      # these timestamps are the Hyrax managed fields, not rails timestamps
      if work.date_uploaded
        work.date_modified = Time.current
      else
        work.date_uploaded = Time.current
      end
    end

    # Returns the desired admin set for the work
    # TODO: do something smarter than just returning the default admin set
    def admin_set_for_work
      @admin_set_for_work ||= AdminSet.find(Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s)
    end

    def set_work_parent(work, pfwork)
      return unless pfwork.parent
      # Works can have either collections OR other works as their parents
      # for collections, set the relationship on the work
      parent_collection = Collection.where(primary_identifier_ssi: pfwork.parent).first
      work.member_of_collections << parent_collection if parent_collection
      # for works, set the relationship on the parent work
      parent_work = Work.where(primary_identifier_ssi: pfwork.parent).first
      parent_work.ordered_members << work if parent_work
      parent_work&.save!
      # if we need to make this code faster,
      # find a way to accumulate all the children and then
      # save the ordered list of children all at once.
    end

    # rubocop:disable Metrics/AbcSize
    def create_or_update_files(work, pfwork)
      # Cases
      # - new work, new files
      # - existing work, update files - NOT IMPLEMENTED YET
      # - existing work, add files - NOT IMPLEMENTED YET
      # - existing work, delete files - NOT SUPPORTED
      file_sets = pfwork.children.filter { |x| x.is_a? Tenejo::PFFile }.map do |pffile|
        file_set = FileSet.new
        file_set.label = File.basename(pffile.file)
        file_set.title = pffile.try(:title) ? [pffile.title] : [file_set.label]
        file_set.visibility = pffile.visibility
        file_set.save!
        local_path = File.join(pffile.import_path, pffile.file)
        update_status(pffile, 'started', 'completed') do
          IngestLocalFileJob.perform_now(file_set, local_path, @job.user)
        end
        file_set
      end
      # NOTE: this code does not invoke the :after_fileset_create callback which generates notifications
      # That's probably ok in this context
      # Hyrax.config.callback.callbacks[:after_create_fileset].source
      # => "Hyrax.config.callback.set(:after_create_fileset, warn: false) do |file_set, user|
      #       Hyrax.publisher.publish('file.set.attached', file_set: file_set, user: user)
      #       Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: user)
      #     end"
      return if file_sets.empty?
      work.ordered_members.concat(file_sets)
      work.thumbnail ||= file_sets.first
      work.representative ||= file_sets.first
      work.save!
    end
    # rubocop:enable Metrics/AbcSize

    def save_work(work)
      return unless work
      newly_created = !work.persisted?
      work.save!
      # Add Sipity workflow to newly created works
      Hyrax::Workflow::WorkflowFactory.create(work, {}, @job.user) if newly_created
      # update job status table - work creation successful
    end

    def self.default_collection_type
      @default_collection_type ||= Hyrax::CollectionType.find_or_create_default_collection_type
    end

    # This method largely exists to recover from cases where
    # ActiveFedora::Cleaner.clean! has been called during test suite runs
    # And inadvertently wiped out the memoized object.
    def self.reset_default_collection_type!
      @default_collection_type = nil
    end

    def rights_statement_authority
      @rights_statement_authority ||= Hyrax.config.rights_statement_service_class.new.authority
    end

    def copyright_not_evaluated
      @copyright_not_evaluated ||= rights_statement_authority.search('not evaluated').first['id']
    end

    def self.collection_attributes_to_copy
      @collection_attributes_to_copy ||=
        ((Collection.terms & Tenejo::PFCollection::ALL_FIELDS) - collection_fields_to_exclude + [:visibility]
        ).map { |key| [key, "#{key}=".to_sym] }.to_h
    end

    def self.collection_fields_to_exclude
      [:collection_type_gid, :depositor, :has_model, :date_uploaded, :create_date, :modified_date, :head, :tail]
    end

    def self.work_attributes_to_copy
      @work_attributes_to_copy ||=
        ((Work.terms & Tenejo::PFWork::ALL_FIELDS) - work_fields_to_exclude + [:visibility]
        ).map { |key| [key, "#{key}=".to_sym] }.to_h
    end

    def self.work_fields_to_exclude
      [:depositor, :has_model, :date_uploaded, :create_date, :modified_date, :head, :tail]
    end
  end
end
