# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Work`
class WorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # override 'canned' indexing of :identifier - see
  # https://github.com/samvera/hyrax/blob/v3.4.1/app/indexers/concerns/hyrax/indexes_linked_metadata.rb#L7
  # https://github.com/samvera/hyrax/blob/v3.4.1/app/indexers/hyrax/deep_indexing_service.rb#L4
  # https://github.com/samvera/hyrax/blob/v3.4.1/app/indexers/hyrax/basic_metadata_indexer.rb#L7
  Hyrax::BasicMetadataIndexer.stored_fields.delete(:identifier)

  # Uncomment this block if you want to add custom indexing behavior:
  # def generate_solr_document
  #  super.tap do |solr_doc|
  #    solr_doc['my_custom_field_ssim'] = object.my_custom_property
  #  end
  # end
end
