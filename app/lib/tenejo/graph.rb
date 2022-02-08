# frozen_string_literal: true
require 'tenejo/pf_object'
require 'csv'
class Tenejo::Graph
  attr_accessor :works, :collections, :files, :warnings, :invalids, :fatal_errors, :root
  def initialize
    @fatal_errors = []
    @works = []
    @collections = []
    @files = []
    @warnings = []
    @invalids = []
    @root = Tenejo::PreFlightObj.new(CSV::Row.new([:object_type], ["root"]), 0)
  end

  def finalize
    reject_invalid
    connect_files
    connect_works
  end

  def consume(row, import_path, lineno)
    return if row.to_h.values.all?(nil)
    case row[:object_type]&.downcase
    when 'c', 'collection'
      @collections << Tenejo::PFCollection.new(row.to_h, lineno)
    when 'f', 'file'
      @files += Tenejo::PFFile.unpack(row, lineno, import_path)
    when 'w', 'work'
      @works << Tenejo::PFWork.new(row, lineno, import_path, self)
    else
      @warnings << "Uknown object type on row #{lineno}: #{row[:object_type]}"
    end
    self
  end

  def add_fatal_error(s)
    @fatal_errors << s
  end

  def add_warning(s)
    @warnings << s
  end

  def empty?
    @works.empty? && @files.empty? && @collections.empty?
  end

  def connect_files
    idx = index(@works)
    @files.each do |f|
      if idx.key?(f.parent)
        idx[f.parent].files << f
      else
        @warnings << %/Could not find parent work "#{f.parent}" for file "#{f.file}" on line #{f.lineno} - the file will be ignored/
      end
    end
    self
  end

  def connect_works
    idx = index(@collections).merge(index(@works))
    (@works + @collections).each do |f|
      if idx.key?(f.parent)
        idx[f.parent].children << f
      elsif f.parent.present?
        @warnings << %/Could not find parent work or collection "#{f.parent}" for work or collection "#{f.identifier.first}" on line #{f.lineno}/
        @root.children << f
      else
        @root.children << f
      end
    end
    self
  end

  def index(c, key: :identifier)
    c.index_by { |v| v.send(key).first; }
  end

  def reject_invalid
    @collections, invalid_collections = @collections.partition(&:valid?)
    @works, invalid_works = @works.partition(&:valid?)
    @files, invalid_files = @files.partition(&:valid?)
    @invalids = invalid_collections + invalid_works + invalid_files
    @warnings += @invalids.map { |k| "Invalid #{k} item: #{k.errors.full_messages.join(',')} on line #{k.lineno}" }
  end

  DEFAULT_UPLOAD_PATH = Hyrax.config.upload_path.call
end
