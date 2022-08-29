# frozen_string_literal: true
class BatchExportJob < ApplicationJob
  queue_as :default

  def perform(export_job)
    # probably not optimal, but enough until we get
    # import hammered out
    Tenejo::CsvExporter.new(export_job).run
  end
end
