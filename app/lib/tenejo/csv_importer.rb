# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
module Tenejo
  class CsvImporter
    def initialize(import_job, import_path = csv_import_file_root)
      @job = import_job
      @graph = Tenejo::Preflight.process_csv(import_job.manifest.download, import_path)
      @depositor = import_job.user.user_key
    end

    def csv_import_file_root
      File.join(Hyrax.config.upload_path.call, 'ftp')
    end

    def preflight_errors
      @graph.fatal_errors
    end

    def preflight_warnings
      @graph.warnings
    end

    def invalid_rows
      @graph.invalids
    end

    def import
      return if fatal_errors(@graph)
      @graph.root.children.each do |child|
        instantiate(child)
      end
    end

    def instantiate(node)
      create_or_update(node)
      node.children.each do |child|
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
      work = Work.where(primary_identifer_ssi: node.primary_identifier).first
      return if work.id && work&.thumbnail_id && work&.representative_id
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

    def create_or_update_collection(pfcollection)
      # put all the expensive stuff here
      # and unit test the heck out of it
      collection = find_or_new_collection(pfcollection.identifier, pfcollection.title)
      update_collection_attributes(collection, pfcollection)
      if pfcollection.parent
        parent = Collection.where(primary_identifier_ssi: pfcollection.parent).first
        collection.member_of_collections << parent
      end
      save_collection(collection)
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
      collection_attributes_to_copy.each { |source, dest| collection.send(dest, pfcollection.send(source)) }

      collection.primary_identifier = pfcollection.identifier.first

      # these timestamps are the Hyrax managed fields, not rails timestamps
      if collection.date_uploaded
        collection.date_modified = Time.current
      else
        collection.date_uploaded = Time.current
      end

      collection.depositor ||= job_owner

      # set the collection parent relationship
      return unless pfcollection.parent
      parent = Collection.where(primary_identifier_ssi: pfcollection.parent).first
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
      work = find_or_new_work(pfwork.identifier, pfwork.title)
      update_work_attributes(work, pfwork)
      create_or_update_files(work, pfwork)
      save_work(work)
    end

    # Finds or creates a work by its user supplied identifier
    # returns a valid work or nil
    def find_or_new_work(primary_id, title)
      work_found = Work.where(primary_identifier_ssi: primary_id).last
      return work_found if work_found
      Work.new(
        primary_identifier: primary_id.first,
        title: title,
        depositor: job_owner
      )
    end

    def update_work_attributes(work, pfwork)
      return unless work
      work_attributes_to_copy.each { |source, dest| work.send(dest, pfwork.send(source)) }
      set_work_parent(work, pfwork)
      work.rights_statement = [rights_statements.authority.search(pfwork.rights_statement.first).first["id"]]

      # these timestamps are the Hyrax managed fields, not rails timestamps
      work.primary_identifier = pfwork.identifier.first
      if work.date_uploaded
        work.date_modified = Time.current
      else
        work.date_uploaded = Time.current
      end
      work.depositor ||= job_owner
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

    def create_or_update_files(work, pfwork)
      # Cases
      # - new work, new files
      # - existing work, update files - NOT IMPLEMENTED YET
      # - existing work, add files - NOT IMPLEMENTED YET
      # - existing work, delete files - NOT SUPPORTED
      file_sets = pfwork.files.map do |pffile|
        file_set = FileSet.new
        file_set.label = File.basename(pffile.file)
        file_set.title = pffile.try(:title) ? [pffile.title] : [file_set.label]
        file_set.visibility = pffile.visibility
        file_set.save!
        local_path = File.join(pffile.import_path, pffile.file)
        IngestLocalFileJob.perform_now(file_set, local_path, @job.user)
        file_set
      end
      # NOTE: this code does not invoke the :after_fileset_create callback which generates notifications
      # That's probably ok in this context
      # Hyrax.config.callback.callbacks[:after_create_fileset].source
      # => "Hyrax.config.callback.set(:after_create_fileset, warn: false) do |file_set, user|
      #       Hyrax.publisher.publish('file.set.attached', file_set: file_set, user: user)
      #       Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: user)
      #     end"
      work.ordered_members = file_sets
      work.thumbnail ||= file_sets.first
      work.representative ||= file_sets.first
    end

    def save_work(work)
      return unless work
      begin
        work.save! # do we need to go through the actor stack?
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

    def rights_statements
      @rights_statements ||= Hyrax.config.rights_statement_service_class.new
    end

    def collection_attributes_to_copy
      @collection_attributes_to_copy ||=
        ((Collection.terms & Tenejo::PFCollection::ALL_FIELDS) - collection_fields_to_exclude + [:visibility]
        ).map { |key| [key, "#{key}=".to_sym] }.to_h
    end

    def collection_fields_to_exclude
      [:collection_type_gid, :depositor, :has_model, :date_uploaded, :create_date, :modified_date, :head, :tail]
    end

    def work_attributes_to_copy
      @work_attributes_to_copy ||=
        ((Work.terms & Tenejo::PFWork::ALL_FIELDS) - work_fields_to_exclude + [:visibility]
        ).map { |key| [key, "#{key}=".to_sym] }.to_h
    end

    def work_fields_to_exclude
      [:depositor, :has_model, :date_uploaded, :create_date, :modified_date, :head, :tail]
    end
  end
end
