# frozen_string_literal: true
class BatchImportJob < ApplicationJob
  queue_as :default

  def perform(filename)
    # probably not optimal, but enough until we get
    # import hammered out
    Tenejo::CsvImporter.import(Tenejo::Preflight.process_csv(File.open(filename)))
  end
end
