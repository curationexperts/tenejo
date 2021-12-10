# frozen_string_literal: true
require 'csv'
require 'active_model'
require 'active_support/core_ext/enumerable'
require 'tenejo/pf_object'

module Tenejo
  class DuplicateColumnError < RuntimeError
  end

  class Preflight # rubocop:disable Metrics/ClassLength
    def self.check_unknown_headers(row, graph)
      row.to_h.keys.each do |x|
        graph[:warnings] << "The column \"#{x.dup.encode('UTF-8')}\" is unknown, and will be ignored" unless KNOWN_HEADERS.include? x
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
      return { fatal_errors: "No manifest present" } unless input
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
        connect_works(connect_files(graph))
      rescue EncodingError, CSV::MalformedCSVError
        graph[:fatal_errors] << "File format or encoding not recognized"
      rescue DuplicateColumnError => x
        graph[:fatal_errors] << x.message
      ensure
        csv.close
      end
      graph
    end

    def self.index(c, key: :identifier)
      c.index_by { |v| v.send(key).first; }
    end

    def self.connect_works(graph)
      idx = index(graph[:collection]).merge(index(graph[:work]))
      (graph[:work] + graph[:collection]).each do |f|
        if idx.key?(f.parent)
          idx[f.parent].children << f
        elsif f.parent.present?
          graph[:warnings] << %/Could not find parent work "#{f.parent}" for work "#{f.identifier.first}" on line #{f.lineno}/
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
  DEFAULT_UPLOAD_PATH = ENV.fetch('UPLOAD_PATH', Rails.root.join('tmp', 'uploads'))
end
