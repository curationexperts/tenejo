# frozen_string_literal: true
require 'tenejo/pf_object'

module Tenejo
  class CsvExporter
    EXPORT_HEADERS = ([:identifier, :error, :class, :title] + Tenejo::CsvImporter.collection_attributes_to_copy.keys + Tenejo::CsvImporter.work_attributes_to_copy.keys).uniq

    def initialize(export_job)
      @export = export_job
    end

    def run
      Tempfile.create(['export-', '.csv']) do |csv|
        csv << EXPORT_HEADERS.join(',') + "\n"
        csv << ",No identifiers provided,\n" if @export.identifiers.empty?
        @export.identifiers.each do |id|
          csv << serialize(id)
        end
        csv.rewind
        @export.manifest.attach(io: csv, filename: File.basename(csv.path), content_type: 'text/csv')
      end
    end

    private

    def serialize(id)
      obj = ActiveFedora::Base.where(primary_identifier_ssi: id).last
      return "#{id},No match for identifier\n" unless obj
      row = []
      EXPORT_HEADERS.each do |attr|
        val = obj.try(attr)
        if val.is_a?(ActiveTriples::Relation)
          val = (val.to_a.join('|~|') if val.present?)
        end
        val = val.gsub('"', '""') if val.respond_to?(:gsub) # escape double quotes for CSV
        val = %("#{val}") if val.present? # wrap non-empty values in double quotes for CSV
        row << val
      end
      row[0] = id
      row.join(',') + "\n"
    end
  end
end
