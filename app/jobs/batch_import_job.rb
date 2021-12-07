# frozen_string_literal: true
class BatchImportJob < ApplicationJob
  queue_as :default

  def perform(import_job)
    # probably not optimal, but enough until we get
    # import hammered out
    Tenejo::CsvImporter.new(import_job).import
  end
end
