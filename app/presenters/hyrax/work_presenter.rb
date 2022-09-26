# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Work`
module Hyrax
  class WorkPresenter < Hyrax::WorkShowPresenter
    # Date fields
    delegate :date_normalized, :date_created, :date_copyrighted, :date_accepted, :date_issued, :resource_format, :genre, :extent, to: :solr_document
  end
end
