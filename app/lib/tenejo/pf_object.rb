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

    def initialize(h, lineno)
      self.lineno = lineno
      h.delete(:object_type)
      h.each do |k, v|
        if respond_to?("#{k}=") && v.present?
          v = v.split("|~|") if v =~ /\|~\|/
          send("#{k}=", v)
        end
      end
      @children = []
      @lineno = lineno
    end
  end
  class PFCollection < PreFlightObj
    ALL_FIELDS = (Collection.terms + [:deduplication_key, :visibility, :parent]).uniq.freeze
    REQUIRED_FIELDS = (Collection.required_terms + [:identifier, :deduplication_key, :visibility, :creator, :keyword]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
  end

  class PFFile < PreFlightObj
    ALL_FIELDS = [:parent, :file, :resource_type].freeze
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
      row[:files].split("|~|").map do |f|
        cp = row.dup
        cp[:files] = f
        PFFile.new(cp, lineno, import_path)
      end
    end

    def initialize(row, lineno, import_path)
      f = row.to_h.delete(:files)
      row[:file] = f if f
      @import_path = import_path
      super row, lineno
    end
  end

  class PFWork < PreFlightObj
    ALL_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword, :files,
                  :visibility, :license, :parent, :rights_statement, :resource_type,
                  :abstract_or_summary, :date_created, :subject, :language, :publisher, :related_url, :location, :source, :bibliographic_citation].freeze
    REQUIRED_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword, :visibility, :parent].freeze

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
      return if LICENSES["terms"].map { |x| x['term'] }.include?(license)
      warnings[:license] << "License on line #{@lineno} is not recognized and will be left blank"
      @license = ""
    end

    def check_rights
      return if RIGHTS_STATEMENTS["terms"].map { |x| x['term'] }.include?(rights_statement)
      warnings[:rights_statement] << "Rights Statement on line #{@lineno} not recognized or cannot be blank, and will be set to 'Copyright Undetermined'"
      @rights_statement = "Copyright Undetermined"
    end
  end
end
