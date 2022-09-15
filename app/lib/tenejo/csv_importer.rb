# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
module Tenejo
  class CsvImporter
    def typify(hash)
      t = hash['type'].constantize.new
      t.attributes = hash
      t
    end

    def initialize(import_job)
      @job = import_job
      @graph = Tenejo::Graph.new
      @graph.attributes = @job.graph # comes out of db as hash
      @root = Tenejo::PreFlightObj.new
      @root.attributes = @graph.root
      @children = @root.children.map { |x| typify(x) }
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
      @graph&.fatal_errors
    end

    def preflight_warnings
      @graph.warnings
    end

    def invalid_rows
      @graph.invalids
    end

    def import
      return if fatal_errors(@graph)
      @job.status = :in_progress
      @job.save!
      @children.each do |child|
        instantiate(child)
      end
      @job.collections = @graph.collections.count
      @job.works = @graph.works.count
      @job.files = @graph.files.count
      @job.completed_at = Time.current
      @job.status = :completed
      @job.save
    end

    def instantiate(node)
      create_or_update(node)
      node.children.map { |x| typify(x) }.each do |child|
        instantiate(child)
      end
      ensure_thumbnails(node)
    end

    def create_or_update(node)
      case node
      when Tenejo::PFCollection
        create_or_update_collection(node)
      when Tenejo::PFWork
        create_or_update_work(node)
      else
        @graph.add_fatal_error("Row: #{node.lineno} - Did not create #{node.class} with identifier #{node.identifier} ")
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

    def search(item, child_id)
      found = item.children.find { |x| x['identifier'] == child_id }
      if !found && !item.children.empty?
        item.children.each do |x|
          found ||= search(typify(x), child_id)
        end
      end
      found
    end

    # TODO: make pfffiles live in the children array, so we don't have to search
    # for them separately
    def search_file(item, file_id)
      # search under the files key instead of children
      found = item.files.find { |x| x['identifier'] == file_id } if item.respond_to?(:files)
      if !found && !item.children.empty?
        item.children.each do |x|
          found ||= search_file(typify(x), file_id)
        end
      end
      found
    end

    # TODO: make pfffiles live in the children array, so we don't have to search
    # for them separately
    def update_file(file_id, status)
      file = search_file(@root, file_id)
      return unless file
      file['status'] = status
      @job.graph = @graph
      @job.save!
    end

    def update_child(child_id, status)
      child = search(@root, child_id)
      return unless child
      child['status'] = status
      @job.graph = @graph
      @job.save!
    end

    def create_or_update_collection(pfcollection)
      # put all the expensive stuff here
      # and unit test the heck out of it
      update_child(pfcollection.identifier, 'started')
      collection = find_or_new_collection(pfcollection.identifier, pfcollection.title)
      update_collection_attributes(collection, pfcollection)
      if pfcollection.parent
        parent = Collection.where(primary_identifier_ssi: pfcollection.parent).first
        collection.member_of_collections << parent if parent
      end
      save_collection(collection)
      update_child(pfcollection.identifier, 'complete')
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
      update_child(pfwork.identifier, 'started')
      work = find_or_new_work(pfwork.identifier, pfwork.title)
      update_work_attributes(work, pfwork)
      create_or_update_files(work, pfwork)
      save_work(work)
      update_child(pfwork.identifier, 'complete')
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
      file_sets = pfwork.files.map { |x| typify(x) }.map do |pffile|
        file_set = FileSet.new
        file_set.label = File.basename(pffile.file)
        file_set.title = pffile.try(:title) ? [pffile.title] : [file_set.label]
        file_set.visibility = pffile.visibility
        file_set.save!
        local_path = File.join(pffile.import_path, pffile.file)
        update_file(pffile.identifier, 'started')
        IngestLocalFileJob.perform_now(file_set, local_path, @job.user)
        update_file(pffile.identifier, 'complete')
        file_set
      end
      # NOTE: this code does not invoke the :after_fileset_create callback which generates notifications
      # That's probably ok in this context
      # Hyrax.config.callback.callbacks[:after_create_fileset].source
      # => "Hyrax.config.callback.set(:after_create_fileset, warn: false) do |file_set, user|
      #       Hyrax.publisher.publish('file.set.attached', file_set: file_set, user: user)
      #       Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: user)
      #     end"
      work.ordered_members.concat(file_sets)
      work.thumbnail ||= file_sets.first
      work.representative ||= file_sets.first
    end
    # rubocop:enable Metrics/AbcSize

    def save_work(work)
      return unless work
      begin
        newly_created = !work.persisted?
        work.save!
        # Add Sipity workflow to newly created works
        Hyrax::Workflow::WorkflowFactory.create(work, {}, @job.user) if newly_created
        # update job status table - work creation successful
      rescue
        # update job status table - work creation failed - save error to table
      end
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
