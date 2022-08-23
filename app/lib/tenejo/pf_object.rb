# frozen_string_literal: true
module Tenejo
  LICENSES = YAML.safe_load(File.open(Rails.root.join("config/authorities/licenses.yml")))
  RESOURCE_TYPES = YAML.safe_load(File.open(Rails.root.join("config/authorities/resource_types.yml")))
  RIGHTS_STATEMENTS = YAML.safe_load(File.open(Rails.root.join("config/authorities/rights_statements.yml")))

  class PreFlightObj
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON
    attr_accessor :lineno, :children, :visibility, :type, :status

    def warnings
      @warnings ||= Hash.new { |h, k| h[k] = [] }
    end

    def warnings=(hash)
      @warnings = warnings.merge(hash)
    end

    def attributes=(hash)
      hash.each do |k, v|
        send("#{k}=", v)
      end
    end

    def attributes
      { lineno: nil, children: [], visibility: nil, warnings: [], type: nil, status: 'not_started' }
    end

    def initialize(row = [], lineno = 0, type: self.class.name)
      self.lineno = lineno
      @type = type
      row.delete(:object_type)
      row.each do |field_name, value|
        set_attribute(field_name, value, lineno)
      end
      @children = []
      @lineno = lineno
      @visibility = transform_visibility
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

    def transform_visibility
      case visibility&.downcase
      when 'public', 'open'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      when 'authenticated'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      when 'private', 'restricted'
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      else
        warnings[:visibility] << "Visibility on line #{lineno} is #{visibility ? 'invalid: ' + visibility : 'blank'} - and will be treated as private"
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end

  class PFCollection < PreFlightObj
    ALL_FIELDS = (Collection.terms + [:visibility, :parent]).uniq.freeze
    REQUIRED_FIELDS = (Collection.required_terms + [:identifier, :visibility]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)

    def attributes
      ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - Collection.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end

  class PFFile < PreFlightObj
    ALL_FIELDS = [:parent, :file, :files, :resource_type, :visibility, :identifier].freeze
    REQUIRED_FIELDS = [:parent, :file].freeze
    attr_accessor(*ALL_FIELDS)
    attr_reader :import_path
    validates_presence_of(*REQUIRED_FIELDS)
    validates_each :file, allow_blank: true, allow_nil: true do |rec, att, val|
      rec.errors.add(att, "Could not find file #{val} at #{rec.import_path}") unless PFFile.exist?(rec, val)
    end
    validates_each :resource_type, allow_blank: true, allow_nil: true do |rec, _att, val|
      rec.warnings[:resource_type] << "Resource type \"#{val}\" on line #{rec.lineno} is not recognized and will be left blank." unless RESOURCE_TYPES["terms"].map { |x| x["term"] }.include?(val)
    end
    def attributes
      a = ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
      a[:import_path] = nil
      a
    end

    def self.exist?(rec, val)
      File.exist?(File.join(rec.import_path, val))
    end

    def self.unpack(row, lineno, import_root)
      cp = row.dup
      index = 1
      packed = row[:files].include?("|~|")
      base_id = row[:identifier]
      base_id = row[:identifier] = row[:parent] + "//L#{lineno}" if base_id.blank?
      files = row[:files].split("|~|").map do |f|
        cp[:files] = f
        cp[:identifier] = "#{base_id}.#{index}" if packed
        index += 1
        PFFile.new(cp, lineno, import_root)
      end
      files
    end

    def initialize(row, lineno, import_root, strict_paths: true)
      file_name = row.to_h.delete(:files)
      row[:file] = relative_path(file_name, import_root, strict_paths)
      @import_path = import_root
      super row, lineno
    end

    def relative_path(file_name, import_root, strict_paths)
      return file_name if strict_paths
      base_name = File.basename(file_name)
      Dir.chdir(import_root) do
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

    def attributes
      ALL_FIELDS.each_with_object(super) { |x, m| m[x.to_sym] = nil; }
    end
    validates_presence_of(*REQUIRED_FIELDS)

    def initialize(row = [], lineno = 0, import_path = nil, graph = nil)
      @files = []
      @import_path = import_path
      return unless graph
      graph.files += unpack_files_from_work(row, lineno, import_path) if row[:files]
      row.delete(:files)
      super(row, lineno)
      check_license
      check_rights
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

    def unpack_files_from_work(row, lineno, import_path)
      files = CSV::Row.new(row.headers, row.fields)
      files[:parent] = files[:identifier]
      files[:object_type] = "file"
      PFFile.unpack(files, lineno, import_path)
    end

    def self.singular_fields
      @singular_fields ||= (ALL_FIELDS - Work.properties.select { |_k, v| v["multiple"] }.keys.map(&:to_sym)).sort
    end
  end
end
