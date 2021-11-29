# frozen_string_literal: true
require 'csv'
require 'active_model'
require 'active_support/core_ext/enumerable'

module Tenejo
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
        if respond_to?("#{k}=")
          send("#{k}=", v) if v.present?
        end
      end
      @children = []
    end
  end

  class PFFile < PreFlightObj
    ALL_FIELDS = [:parent, :file, :resource_type].freeze
    REQUIRED_FIELDS = [:parent, :file].freeze
    attr_accessor(*ALL_FIELDS)
    attr_reader :import_path
    validates_presence_of(*REQUIRED_FIELDS)
    validates_each :file do |rec, att, val|
      rec.errors.add(att, "Could not find file #{val} at #{rec.import_path}") if val.present? && !File.exist?(File.join(rec.import_path, val))
    end
    validates_each :resource_type do |rec, att, val|
      if val.present?
        rec.errors.add(att, "Resource type #{val} is not recognized and will be left blank.") unless RESOURCE_TYPES["terms"].map { |x| x["term"] }.include?(val)
      end
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
    def initialize(row, lineno)
      @files = []
      super
      check_license
      check_rights
    end

    def check_license
      return if license.blank?
      return if LICENSES["terms"].map { |x| x['term'] }.include?(license)
      warnings[:license] << "License is not recognized and will be left blank"
      @license = ""
    end

    def check_rights
      return if RIGHTS_STATEMENTS["terms"].map { |x| x['term'] }.include?(rights_statement)
      warnings[:rights_statement] << "Rights Statement not recognized or cannot be blank, and will be set to 'Copyright Undetermined'"
      @rights_statement = "Copyright Undetermined"
    end
  end

  class PFCollection < PreFlightObj
    ALL_FIELDS = (Collection.terms + [:deduplication_key, :visibility, :parent]).uniq.freeze
    REQUIRED_FIELDS = (Collection.required_terms + [:identifier, :deduplication_key, :visibility, :creator, :keyword]).uniq.freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
  end

  class DuplicateColumnError < RuntimeError
  end

  class Preflight # rubocop:disable Metrics/ClassLength
    def self.check_unknown_headers(row, graph)
      row.to_h.keys.each do |x|
        graph[:warnings] << "The column \"#{x}\" is unknown, and will be ignored" unless KNOWN_HEADERS.include? x
      end
    end

    def self.check_duplicate_headers(row)
      all = row.map(&:first)
      dupes = all.select { |x| all.count(x) > 1 }
      raise DuplicateColumnError, "Duplicate column names detected #{dupes}, cannot process" unless dupes.empty?
      row.length
    end

    def self.should_skip?(row, lineno)
      (row.to_h.values.all?(nil) || lineno == 1)
    end

    def self.init_graph
      graph = Hash.new { |h, k| h[k] = [] }
      graph[:fatal_errors] = []
      graph[:warnings] = []
      graph
    end

    def self.empty_graph?(graph)
      (graph[:work] + graph[:file] + graph[:collection]).empty?
    end

    def self.check_length(row, headerlen, lineno, graph)
      if row.chunk.size != headerlen && !row.map(&:last).all?(nil)
        graph[:warnings] << "The number of columns in row #{lineno} differed from the number of headers (missing quotation mark?)"
        false
      else
        true
      end
    end

    def self.map_header(m)
      squashed = m.downcase.gsub(/[^0-9A-Za-z]/, '')
      KNOWN_HEADERS.find { |x| x.to_s.gsub(/[^0-9A-Za-z]/, '') == squashed } || m
    end

    def self.read_csv(filename, import_path = DEFAULT_UPLOAD_PATH)
      stream = File.open(filename)
      begin
        process_csv(stream, import_path)
      ensure
        stream.close
      end
    end

    def self.process_csv(input, import_path = DEFAULT_UPLOAD_PATH)
      begin
        csv = CSV.new(input, headers: true, return_headers: true, skip_blanks: true,
                       header_converters: [->(m) { map_header(m) }])
        graph = init_graph
        headerlen = 0
        csv.each do |row|
          if csv.lineno == 1 # is header, headers are already transformed by the above
            headerlen = check_duplicate_headers(row)
            check_unknown_headers(row, graph)
            next
          end
          next unless check_length(row, headerlen, csv.lineno, graph)
          parse_to_type(row, import_path, csv.lineno, graph)
        end
        graph[:fatal_errors] << "No data was detected" if empty_graph?(graph)
      rescue CSV::MalformedCSVError => x
        graph[:fatal_errors] << "Could not recognize this file format: #{x.message}"
      rescue DuplicateColumnError => x
        graph[:fatal_errors] << x.message
      ensure
        csv.close
      end
      connect_works(connect_files(graph))
    end

    def self.index(c, key: :identifier)
      c.index_by { |v| v.send(key); }
    end

    def self.connect_works(graph)
      idx = index(graph[:collection]).merge(index(graph[:work]))
      (graph[:work] + graph[:collection]).each do |f|
        if idx.key?(f.parent)
          idx[f.parent].children << f
        elsif f.parent.present?
          graph[:warnings] << %/Could not find parent work "#{f.parent}" for work "#{f.identifier}" on line #{f.lineno}/
        end
      end
      graph
    end

    def self.connect_files(graph)
      idx = index(graph[:work])
      graph[:file].each do |f|
        if idx.key?(f.parent)
          idx[f.parent].files << f
        else
          graph[:warnings] << %/Could not find parent work "#{f.parent}" for file "#{f.file}" on line #{f.lineno}/
        end
      end
      graph
    end

    def self.parse_to_type(row, import_path, lineno, output)
      return output if row.to_h.values.all?(nil)
      case row[:object_type].downcase
      when 'c', 'collection'
        output[:collection] << PFCollection.new(row.to_h, lineno)
      when 'f', 'file'
        output[:file] += PFFile.unpack(row, lineno, import_path)
      when 'w', 'work'
        output[:work] << PFWork.new(row, lineno)
      else
        output[:warnings] << "Uknown object type on row #{lineno}: #{row[:object_type]}"
      end
      output
    end
  end

  KNOWN_HEADERS = Tenejo::PFWork::ALL_FIELDS + Tenejo::PFCollection::ALL_FIELDS + Tenejo::PFFile::ALL_FIELDS + [:object_type]
  LICENSES = YAML.safe_load(File.open(Rails.root.join("config/authorities/licenses.yml")))
  RESOURCE_TYPES = YAML.safe_load(File.open(Rails.root.join("config/authorities/resource_types.yml")))
  RIGHTS_STATEMENTS = YAML.safe_load(File.open(Rails.root.join("config/authorities/rights_statements.yml")))
  DEFAULT_UPLOAD_PATH = ENV.fetch('UPLOAD_PATH', Rails.root.join('tmp', 'uploads'))
end
