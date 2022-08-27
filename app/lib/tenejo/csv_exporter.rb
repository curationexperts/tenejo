# frozen_string_literal: true
require 'tenejo/pf_object'
require 'csv'

module Tenejo
  class CsvExporter
    EXPORT_HEADERS = ([:primary_identifier, :error, :class, :title] + Tenejo::CsvImporter.collection_attributes_to_copy.keys + Tenejo::CsvImporter.work_attributes_to_copy.keys).uniq

    def initialize(export_job)
      @export = export_job
    end

    def run
      output = CSV.generate(encoding: 'UTF-8', write_headers: true) do |csv|
        csv << EXPORT_HEADERS # Header row
        csv << CSV::Row.new([:primary_identifier, :error], ["missing", "No identifiers provided"]) if @export.identifiers.empty?
        @export.identifiers.each do |id|
          csv << serialize(id)
        end
      end

      @export.manifest.attach(io: StringIO.new(output), filename: export_name, content_type: 'text/csv')
    end

    private

    # @return Filename for the exported CSV
    # ex: export-COL001-20201115-172309.csv
    def export_name
      "export-#{@export.identifiers.first}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv"
    end

    # Lookup an ActiveFedora object by it's primary identifier
    # And return a CSV-friendly array of attribute values
    # @param id[String] the primary identifier for the object to serialze
    # @return CSV::Row containing ojbect attributes converted to strings
    def serialize(id)
      obj = ActiveFedora::Base.where(primary_identifier_ssi: id).last
      return CSV::Row.new([:primary_identifier, :error], [id, "No match for identifier"]) unless obj
      values = EXPORT_HEADERS.map { |attr| pack_field(obj.try(attr)) }
      CSV::Row.new(EXPORT_HEADERS, values)
    end

    # Handle multi-value fields and normalize empty fields regardless of underlying class
    # @param obj
    # @return self, nil, or ActviveTriples value converted to a (packed) string
    def pack_field(obj)
      if obj.blank?
        nil
      elsif obj.is_a?(ActiveTriples::Relation)
        obj.join('|~|')
      else
        obj
      end
    end
  end
end
