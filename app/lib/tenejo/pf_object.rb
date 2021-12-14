# frozen_string_literal: true
module Tenejo
  LICENSES = YAML.safe_load(File.open(Rails.root.join("config/authorities/licenses.yml")))
  RESOURCE_TYPES = YAML.safe_load(File.open(Rails.root.join("config/authorities/resource_types.yml")))
  RIGHTS_STATEMENTS = YAML.safe_load(File.open(Rails.root.join("config/authorities/rights_statements.yml")))
  class PreFlightObj
    include ActiveModel::Validations
    attr_accessor :lineno, :children
    def warnings
      @warnings ||= Hash.new { |h, k| h[k] = [] }
    end

    def initialize(row, lineno)
      self.lineno = lineno
      row.delete(:object_type)
      row.each do |field_name, value|
        set_attribute(field_name, value, lineno)
      end
      @children = []
      @lineno = lineno
    end

    def set_attribute(field_name, value, lineno)
      setter = "#{field_name}="
      return if value.nil?
      list = value.split("|~|")
      if singular?(field_name)
        unpacked_value = list&.shift
        warnings[field_name] << "#{field_name.to_s.titlecase} on line #{lineno} has extra values: using '#{unpacked_value}' -- ignoring: '#{list.join(', ')}'" if list.count != 0
      else
        unpacked_value = list
      end
      send(setter, unpacked_value) if respond_to?(setter)
    end

    def singular?(attribute_name)
      self.class.singular_fields.include?(attribute_name)
    end

    def self.singular_fields
      raise NotImplementedError
    end
  end

  class PFCollection < PreFlightObj
    ALL_FIELDS = (Collection.terms + [:visibility, :parent]).uniq.freeze
    REQUIRED_FIELDS = (Collection.required_terms + [:identifier, :visibility]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - Collection.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end

  class PFFile < PreFlightObj
    ALL_FIELDS = [:parent, :file, :files, :resource_type].freeze
    REQUIRED_FIELDS = [:parent, :file].freeze
    attr_accessor(*ALL_FIELDS)
    attr_reader :import_path
    validates_presence_of(*REQUIRED_FIELDS)
    validates_each :file, allow_blank: true, allow_nil: true do |rec, att, val|
      rec.errors.add(att, "Could not find file #{val} at #{rec.import_path}") unless File.exist?(File.join(rec.import_path, val))
    end
    validates_each :resource_type, allow_blank: true, allow_nil: true do |rec, _att, val|
      rec.warnings[:resource_type] << "Resource type \"#{val}\" on line #{rec.lineno} is not recognized and will be left blank." unless RESOURCE_TYPES["terms"].map { |x| x["term"] }.include?(val)
    end

    def self.unpack(row, lineno, import_path)
      files = row[:files].split("|~|").map do |f|
        cp = row.dup
        cp[:files] = f
        PFFile.new(cp, lineno, import_path)
      end
      files
    end

    def initialize(row, lineno, import_path)
      f = row.to_h.delete(:files)
      row[:file] = f if f
      @import_path = import_path
      super row, lineno
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - FileSet.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end

  class PFWork < PreFlightObj
    ALL_FIELDS = (Work.terms + [:visibility, :parent, :files]).uniq.freeze
    REQUIRED_FIELDS = (Work.required_terms + [:identifier, :visibility]).uniq.freeze

    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)

    validates_each :visibility, allow_blank: true, allow_nil: true do |rec, attr, val|
      rec.errors.add(attr, "Unknown visibility \"#{val}\" on line #{rec.lineno}") unless [:open, :registered, :restricted].include?(val.to_sym)
    end
    def transform_visibility
      return if visibility.nil?
      case visibility.downcase
      when 'public'
        :open
      when 'authenticated'
        :registered
      when 'private'
        :restricted
      else
        visibility
      end
    end

    def initialize(row, lineno)
      @files = []
      super
      check_license
      check_rights
      @visibility = transform_visibility
    end

    def check_license
      return if license.blank?
      first_license = license&.shift
      warnings[:license] << "Multiple licenses on line 1: using '#{first_license}' -- ignoring '#{license.join(', ')}'" if license.count != 0

      return @license = [first_license] if LICENSES["terms"].map { |x| x['term'] }.include?(first_license)
      warnings[:license] << "License on line #{@lineno} is not recognized and will be left blank"
      @license = self.class.singular_fields.include?(:license) ? "" : []
    end

    def check_rights
      return if RIGHTS_STATEMENTS["terms"].map { |x| x['term'] }.include?(rights_statement&.first)
      warnings[:rights_statement] << "Rights Statement on line #{@lineno} not recognized or cannot be blank, and will be set to 'Copyright Undetermined'"
      @rights_statement = ["Copyright Undetermined"]
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - Work.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end
end
