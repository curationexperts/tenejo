# frozen_string_literal: true

module Tenejo
  class CsvImporter
    def initialize(import_job)
      @job = import_job
      @graph = Tenejo::Preflight.process_csv(import_job.manifest.download)
      @depositor = import_job.user.user_key
    end

    def import
      return if fatal_errors(@graph)
      make_collections(@graph)
      make_works(@graph)
      make_files(@graph)
    end

    def fatal_errors(graph)
      graph[:fatal_errors]&.any?
    end

    def job_owner
      @depositor
    end

    def make_collections(graph)
      graph[:collection].each do |pfcollection|
        create_or_update_collection(pfcollection)
      end
    end

    def create_or_update_collection(pfcollection)
      # put all the expensive stuff here
      # and unit test the heck out of it
      collection = find_or_new_collection(pfcollection.identifier, pfcollection.title)
      update_collection_attributes(collection, pfcollection)
      save_collection(collection)
    end

    # Finds or creates a job by it's user supplied identifier
    # returns a valid collection or nil
    def find_or_new_collection(primary_id, title)
      collection_found = Collection.where(identifier: primary_id).last
      return collection_found if collection_found
      Collection.new(
        identifier: primary_id,
        title: title,
        depositor: job_owner,
        collection_type_gid: Tenejo::CsvImporter.default_collection_type
      )
    end

    def update_collection_attributes(collection, pfcollection)
      return unless collection
      attributes_to_copy.each { |source, dest| collection.send(dest, pfcollection.send(source)) }
      # set the parent collection
      # these timestamps are the Hyrax managed fields, not rails timestamps
      if collection.date_uploaded
        collection.date_modified = Time.current
      else
        collection.date_uploaded = Time.current
      end
      collection.depositor ||= job_owner
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

    def make_works(graph)
      graph[:work].each do |pfwork|
        create_or_update_work(pfwork)
      end
    end

    def create_or_update_work(pfwork)
      # expensive stuff here
    end

    def make_files(graph)
      graph[:file].each do |pffile|
        create_or_update_file(pffile)
      end
    end

    def create_or_update_file(pffile)
      # expensive stuff here
    end

    def self.default_collection_type
      @default_collection_type ||= Hyrax::CollectionType.find_or_create_default_collection_type
    end

    def attributes_to_copy
      @attributes_to_copy ||=
        ((Collection.terms & Tenejo::PFCollection::ALL_FIELDS) - fields_to_exclude
        ).map { |key| [key, "#{key}=".to_sym] }.to_h
    end

    def fields_to_exclude
      [:collection_type_gid, :depositor, :has_model, :date_uploaded, :create_date, :modified_date, :head, :tail]
    end
  end
end
