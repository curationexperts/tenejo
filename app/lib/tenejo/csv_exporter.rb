# frozen_string_literal: true

require 'tenejo/pf_object'
require 'csv'

module Tenejo
  class CsvExporter
    EXCLUDE_FROM_EXPORT = [:date_modified, :identifier, :label, :arkivo_checksum, :state].freeze
    HEADER_ROW = (([:primary_identifier, :error, :class, :title] \
                  + Tenejo::CsvImporter.collection_attributes_to_copy.keys \
                  + Tenejo::CsvImporter.work_attributes_to_copy.keys).uniq \
                  - EXCLUDE_FROM_EXPORT).freeze

    def initialize(export_job)
      @export = export_job
    end

    def run
      @export.status = :in_progress
      @export.save
      output = StringIO.new(generate_csv)
      @export.manifest.attach(io: output, filename: export_name, content_type: 'text/csv')
      @export.status = :completed
      @export.completed_at = Time.current
      @export.save
    end

    def generate_csv
      csv_string = CSV.generate(encoding: 'UTF-8', write_headers: true) do |csv|
        csv << HEADER_ROW
        csv << CSV::Row.new([:primary_identifier, :error], ["missing", "No identifiers provided"]) if @export.identifiers.empty?
        @export.identifiers.each do |id|
          csv << serialize(id)
        end
      end

      # TODO: remove this after refactoring Tenejo metadata to rename primary_identifier and identifer
      csv_string.gsub!('primary_identifier,error,class,', 'identifier,error,object type,')
      csv_string
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
      values = HEADER_ROW.map { |attr| pack_field(obj.try(attr)) }
      CSV::Row.new(HEADER_ROW, values)
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
