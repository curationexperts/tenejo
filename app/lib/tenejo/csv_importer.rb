# frozen_string_literal: true

module Tenejo
  class CsvImporter
    COLLECTION_PROPERTIES = [
      'abstract',
      'access_right',
      'alternative_title',
      'based_near',
      'bibliographic_citation',
      # 'collection_type_gid',
      'contributor',
      'create_date',
      'creator',
      'date_created',
      # 'date_modified',
      # 'date_uploaded',
      'depositor',
      'description',
      # 'has_model',
      # 'head',
      'identifier',
      # 'import_url',
      'keyword',
      'label',
      'language',
      'license',
      'modified_date',
      'publisher',
      'related_url',
      'relative_path',
      'resource_type',
      'rights_notes',
      'rights_statement',
      'source',
      'subject',
      # 'tail',
      'title'
    ].freeze

    def self.import(graph)
      default_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type

      graph[:collection].each do |collection_params|
        begin
          collection = Collection.find(collection_params[:identifier])
        rescue ActiveFedora::ObjectNotFoundError
          collection = Collection.new(id: collection_params[:identifier], collection_type_gid: default_collection_type.gid)
        end
        collection.title = collection_params[:title]
        collection.description = collection_params[:description]
        collection.date_modified = collection.date_uploaded = Time.current
        collection.save
      end
    end
  end
end
