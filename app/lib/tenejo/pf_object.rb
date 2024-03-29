# frozen_string_literal: true
module Tenejo
  class LicenseValidator < ActiveModel::Validator
    def validate(record)
      licenses = Array.wrap(record.license).select(&:present?)
      matched, invalid = licenses.partition { |license| license_id_lookup[license] }
      invalid.each do |license|
        record.warnings[:license] << "License '#{license}' is not recognized and will be omitted"
      end
      record.license = matched.map { |license| license_id_lookup[license] }.uniq
    end

    def license_id_lookup
      @license_lookup ||= license_authority.flat_map { |e| [[e[:id], e[:id]], [e[:label], e[:id]]] }.to_h
    end

    def license_authority
      @license_authority ||= Hyrax.config.license_service_class.new.active_elements
    end
  end

  class ResourceTypeValidator < ActiveModel::Validator
    RESOURCE_TYPES = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }.map { |term| term[:id] }

    def validate(record)
      return unless record.resource_type
      record.resource_type, invalid_names = record.resource_type.partition { |term| RESOURCE_TYPES.include?(term) }
      invalid_names.each do |term|
        record.warnings[:resource_type] << "Resource Type '#{term}' is not recognized and will be omitted."
      end
    end
  end

  class RightsValidator < ActiveModel::Validator
    def validate(record)
      rights_statements = Array.wrap(record.rights_statement)
      rights = rights_statements.first
      matched = rights_statement_authority.find { |r| r.key(rights) }
      if matched
        record.rights_statement = [matched[:id]]
      else
        record.warnings[:rights_statement] << main_warning(rights)
        record.rights_statement = ['https://rightsstatements.org/vocab/UND/1.0/']
      end
      other_warnings(record, rights_statements)
    end

    def main_warning(rights)
      if rights.present?
        "Rights Statement '#{rights}' is not recognized and will be set to 'Copyright Undetermined'"
      else
        "Rights Statement cannot be blank and will be set to 'Copyright Undetermined'"
      end
    end

    def other_warnings(record, rights_statements)
      record.warnings[:rights_statement] << "Rights Statement includes extra values which will be ignored" if rights_statements.count > 1
    end

    def rights_statement_authority
      @rights_statement_authority ||= Hyrax.config.rights_statement_service_class.new.active_elements
    end
  end

  class PreFlightObj
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON
    attr_accessor :lineno, :children, :visibility, :type, :status, :messages

    def warnings
      @warnings ||= Hash.new { |h, k| h[k] = [] }
    end

    def warnings=(hash)
      @warnings = warnings.merge(hash)
    end

    def collections
      children.select { |x| x.is_a?(Tenejo::PFCollection) }
    end

    def works
      children.select { |x| x.is_a?(Tenejo::PFWork) }
    end

    def files
      children.select { |x| x.is_a?(Tenejo::PFFile) }
    end

    def self.typify(hash)
      if hash.is_a?(Hash) && hash.key?('type')
        # puts "#{hash['type']} id: #{hash['identifier']} parent: #{hash['parent']}"
        t = hash['type'].constantize.new
        t.attributes = hash
        t
      else
        hash
      end
    end

    def attributes=(hash)
      hash.each do |k, v|
        v = if v.is_a?(Array)
              v.map { |x| self.class.typify(x) }
            else
              self.class.typify(v)
            end
        send("#{k}=", v)
      end
    end

    def attributes
      { lineno: nil, children: [], visibility: nil, warnings: [], type: nil, status: 'not_started', messages: [] }
    end

    def initialize(row = {}, lineno = 0, type: self.class.name)
      self.lineno = lineno
      @type = type
      row.delete(:object_type)
      row.each do |field_name, value|
        set_attribute(field_name, value)
      end
      @children = []
      @messages = []
      @lineno = lineno
      @visibility = transform_visibility
    end

    def set_attribute(field_name, value)
      setter = "#{field_name}="
      return if value.nil?
      list = value.split("|~|")
      if singular?(field_name)
        unpacked_value = list&.shift
        warnings[field_name] << "#{field_name.to_s.titlecase} has extra values: using '#{unpacked_value}' -- ignoring: '#{list.join(', ')}'" if list.count != 0
      else
        unpacked_value = list
      end
      send(setter, unpacked_value) if respond_to?(setter)
    end

    def singular?(attribute_name)
      self.class.singular_fields.include?(attribute_name.to_sym)
    end

    def self.singular_fields
      raise NotImplementedError
    end

    def transform_visibility
      case visibility&.downcase
      when 'public', 'open'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      when 'authenticated'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      when 'private', 'restricted'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      else
        warnings[:visibility] << "Visibility is #{visibility ? 'invalid: ' + visibility : 'blank'} - and will be treated as private"
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end

  class PFCollection < PreFlightObj
    ALL_FIELDS = (Collection.terms + [:visibility, :parent]).uniq.freeze
    REQUIRED_FIELDS = (Collection.required_terms + [:identifier, :visibility]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
    validates_with Tenejo::ResourceTypeValidator

    def attributes
      ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - Collection.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end

  class PFFile < PreFlightObj
    ALL_FIELDS = [:status, :parent, :label, :file, :files, :resource_type, :visibility, :identifier, :import_path].freeze
    REQUIRED_FIELDS = [:parent, :file, :identifier].freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
    validates_with Tenejo::ResourceTypeValidator
    validates_each :file, allow_blank: true, allow_nil: true do |rec, att, val|
      rec.errors.add(att, "< #{val} > cannot be found at '#{rec.import_path}'") unless rec.file_exist?
    end

    def attributes
      ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
    end

    def file_exist?
      return true if url?
      File.exist?(File.join(import_path, file))
    end

    def url?
      file&.match(%r{^https?://}i) || false
    end

    def self.unpack(row, lineno, import_path)
      return [invalid_file(row, lineno)] if row[:files].blank?
      cp = row.dup
      index = 1
      packed = row[:files].include?("|~|")
      base_id = row[:identifier]
      base_id = row[:identifier] = row[:parent] + "//L#{lineno}" if base_id.blank?
      files = row[:files].split("|~|").map do |f|
        cp[:files] = f
        cp[:identifier] = "#{base_id}.#{index}" if packed
        index += 1
        PFFile.new(cp, lineno, import_path)
      end
      files
    end

    def self.invalid_file(row, lineno)
      PFFile.new(row, lineno, '')
    end

    def initialize(row = {}, lineno = 0, import_path = '.', strict_paths = true)
      @file = row[:files]
      @label = row[:title]
      @import_path = import_path
      row[:file] = relative_path(strict_paths)
      super row, lineno
    end

    def relative_path(strict_paths = true)
      return file if strict_paths || url? || file.nil?
      base_name = File.basename(file)
      Dir.chdir(import_path) do
        Dir.glob(File.join('**', base_name)).first || "**/#{base_name}"
      end
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - FileSet.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end

  class PFWork < PreFlightObj
    ALL_FIELDS = (Work.terms + [:visibility, :parent, :files]).uniq.freeze
    REQUIRED_FIELDS = (Work.required_terms + [:identifier, :visibility]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_with Tenejo::LicenseValidator
    validates_with Tenejo::ResourceTypeValidator
    validates_with Tenejo::RightsValidator # run before presence validator to ensure rights_statement is set
    validates_presence_of(*REQUIRED_FIELDS)

    def attributes
      ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
    end

    def initialize(row = {}, lineno = 0, _import_path = nil, _graph = nil)
      super(row, lineno)
    end

    def self.singular_fields
      @singular_fields ||= ALL_FIELDS - ([:files] + Work.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym))
    end
  end
end
