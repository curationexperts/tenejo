# frozen_string_literal: true

# Generated by hyrax:models:install
class FileSet < ActiveFedora::Base
  property :primary_identifier, predicate: ::RDF::Vocab::DC11.identifier, multiple: false do |index|
    index.as :stored_sortable
  end
  include ::Hyrax::FileSetBehavior
end
