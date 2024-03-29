# frozen_string_literal: true

require 'tenejo/pf_object'
require 'csv'

module Tenejo
  class CsvExporter
    EXCLUDE_FROM_EXPORT = [:date_modified, :label, :arkivo_checksum, :state].freeze
    HEADER_ROW = (([:identifier, :error, :object_type, :visibility, :parent, :title, :files] \
                  + Tenejo::CsvImporter.collection_attributes_to_copy.keys \
                  + Tenejo::CsvImporter.work_attributes_to_copy.keys).uniq \
                  - EXCLUDE_FROM_EXPORT).freeze

    def initialize(export_job)
      @export = export_job
      @object_type_counts = Hash.new(0)
    end

    def run
      @export.status = :in_progress
      @export.save
      output = StringIO.new(generate_csv)
      @export.manifest.attach(io: output, filename: export_name, content_type: 'text/csv')
      @export.status = :completed
      @export.completed_at = Time.current
      @export.collections = @object_type_counts['Collection']
      @export.works =       @object_type_counts['Work']
      @export.files =       @object_type_counts['File']
      @export.save
    end

    def generate_csv
      csv_string = CSV.generate(encoding: 'UTF-8', write_headers: true) do |csv|
        csv << HEADER_ROW
        csv << CSV::Row.new([:identifier, :error], ["missing", "No identifiers provided"]) if @export.identifiers.empty?
        @export.identifiers.each do |id|
          find_and_export(id, csv)
        end
      end
      csv_string
    end

    private

    # @return Filename for the exported CSV
    # ex: export-COL001-20201115-172309.csv
    def export_name
      "export-#{@export.identifiers.first}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv"
    end

    # Lookup an ActiveFedora object by it's primary identifier
    # And append it's metadata and metadata of descendants to a CSV
    # @param id[String] the primary identifier for the object to serialze
    # @param csv[CSV] a CSV IO object to append the metadata to
    def find_and_export(id, csv)
      obj = ActiveFedora::Base.where(identifier_ssi: id).last
      csv << CSV::Row.new([:identifier, :error], [id, "No match for identifier"]) unless obj
      serialize_with_descendants(obj, nil, csv)
    end

    # Serialize the metadata for an ActiveFedora object in a CSV-friendly format
    # And then recursively do the same for any child collections and works
    # @param obj[ActiveFedora::Base] the object to serialze
    # @param parent_id[String] the primary identifier of the object's parent
    # @param csv[CSV] a CSV IO object to append the metadata to
    def serialize_with_descendants(obj, parent_id, csv)
      return unless obj
      csv << serialize(obj, parent_id)
      serialize_children(csv, obj)
    end

    def serialize_children(csv, obj)
      parent_id = obj.identifier
      obj.try(:child_collections)&.map { |child| serialize_with_descendants(child, parent_id, csv) }
      obj.try(:child_works)&.map { |child| serialize_with_descendants(child, parent_id, csv) }
      obj.try(:ordered_file_sets)&.map { |child| serialize_with_descendants(child, parent_id, csv) }
    end

    def download_url(obj)
      return unless obj.is_a? FileSet
      Hyrax::Engine.routes.url_helpers.download_url(obj.id)
    end

    def serialize(obj, parent_id = nil)
      return unless obj
      values = HEADER_ROW.map { |attr| pack_field(obj.try(attr)) }
      row = CSV::Row.new(HEADER_ROW, values)
      row[:parent] = parent_id
      row[:identifier] = obj.identifier || obj.id
      row[:files] = download_url(obj)
      row[:object_type] = obj.class.to_s.gsub('FileSet', 'File')
      @object_type_counts[row[:object_type]] = @object_type_counts[row[:object_type]] + 1
      row
    end

    # Handle multi-value fields regardless of underlying class
    # @param obj
    # @return self or array-like value converted to a (packed) string
    def pack_field(obj)
      if obj.respond_to?(:join)
        obj.join('|~|')
      else
        obj
      end
    end
  end
end
