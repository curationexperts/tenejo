# frozen_string_literal: true
require 'csv'
require 'active_model'
require 'active_support/core_ext/enumerable'
require 'tenejo/graph'

module Tenejo
  KNOWN_HEADERS = Tenejo::PFWork::ALL_FIELDS + Tenejo::PFCollection::ALL_FIELDS + Tenejo::PFFile::ALL_FIELDS + [:object_type]
  DEFAULT_UPLOAD_PATH = File.join(Hyrax.config.upload_path.call, 'ftp')
  class DuplicateColumnError < RuntimeError; end
  class MissingIdentifierError < RuntimeError; end

  class Preflight # rubocop:disable Metrics/ClassLength
    def self.check_unknown_headers(row, graph)
      row.to_h.keys.each do |x|
        graph.add_warning "The column \"#{x.dup.encode('UTF-8')}\" is unknown, and will be ignored" unless KNOWN_HEADERS.include? x
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

    def self.check_length(row, headerlen, lineno, graph)
      if row.chunk.size != headerlen && !row.map(&:last).all?(nil)
        graph.add_warning "The number of columns in row #{lineno} differed from the number of headers (missing quotation mark?)"
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

    def self.process_csv(input, import_path = DEFAULT_UPLOAD_PATH) # rubocop:disable Metrics/CyclomaticComplexity
      graph = Graph.new
      graph.add_fatal_error("No manifest present") and return graph unless input
      begin
        csv = CSV.new(input, headers: true, return_headers: true, skip_blanks: true,
                      header_converters: [->(m) { map_header(m) }], encoding: 'UTF-8')
        headers = csv.shift
        raise MissingIdentifierError, "Missing required column 'Identifier'" unless headers.include? :identifier
        headerlen = check_duplicate_headers(headers)
        check_unknown_headers(headers, graph)
        csv.each do |row|
          next unless check_length(row, headerlen, csv.lineno, graph)
          graph.consume(row, import_path, csv.lineno)
        end
        graph.add_fatal_error("No data was detected") if graph.empty?
        graph.finalize
      rescue EncodingError, CSV::MalformedCSVError
        graph.add_fatal_error "File format or encoding not recognized"
      rescue DuplicateColumnError => x
        graph.add_fatal_error x.message
      rescue MissingIdentifierError => x
        graph.add_fatal_error x.message
      end
      graph
    end
  end
end
