# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Work`
class Work < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)

  include ::Tenejo::BasicMetadata
  self.indexer = WorkIndexer

  def self.terms
    @metadata ||= properties.keys.sort.map(&:to_sym)
  end

  def self.required_terms
    @required_metadata ||= Hyrax::WorkForm.required_fields.sort
  end

  def self.editable_terms
    @editable_metadata ||= Hyrax::WorkForm.terms.sort
  end
end
