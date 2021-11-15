# frozen_string_literal: true
require 'csv'
require 'active_model'
require 'active_support/core_ext/enumerable'
module Tenejo
  class PreFlightObj
    include ActiveModel::Validations
    attr_accessor :lineno, :children
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
      rec.errors.add(att, "Could not find file #{val} at #{rec.import_path}") if (val.present? && !File.exist?(File.join(rec.import_path, val)))
    end
    def initialize(h, lineno, import_path)
      f = h.delete(:files)
      h[:file] = f.last if f
      @import_path = import_path
      super h, lineno
    end
  end

  class PFWork < PreFlightObj
    ALL_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword, :files,
                  :visibility, :license, :parent, :rights_statement, :resource_type,
                  :abstract_or_summary, :date_created, :subject, :language, :publisher, :related_url, :location, :source, :bibliographic_citation].freeze
    REQUIRED_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword, :visibility, :license, :parent].freeze

    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
    def initialize(row, lineno)
      @files = []
      super
    end
  end

  class PFCollection < PreFlightObj
    ALL_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword,
                  :visibility, :license, :parent, :resource_type, :abstract_or_summary, :contributor, :publisher].freeze
    REQUIRED_FIELDS = [:title, :identifier, :deduplication_key, :creator, :keyword, :visibility].freeze
    attr_accessor(*ALL_FIELDS)
    validates_presence_of(*REQUIRED_FIELDS)
  end

  class DuplicateColumnError < RuntimeError
  end

  class Preflight
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

    def self.read_csv(input, import_path)
      begin
        csv = CSV.open(input, headers: true, return_headers: true, skip_blanks: true,
                       header_converters: [->(m) { m.downcase.tr(' ', '_').to_sym }])
        graph = init_graph
        headerlen = 0
        csv.each do |row|
          if csv.lineno == 1 # is header
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
        output[:file] << PFFile.new(row, lineno, import_path)
      when 'w', 'work'
        output[:work] << PFWork.new(row, lineno)
      else
        output[:warnings] << "Uknown object type on row #{lineno}: #{row[:object_type]}"
      end
      output
    end
  end
  KNOWN_HEADERS = Tenejo::PFWork::ALL_FIELDS + Tenejo::PFCollection::ALL_FIELDS + Tenejo::PFFile::ALL_FIELDS + [:object_type]
end
