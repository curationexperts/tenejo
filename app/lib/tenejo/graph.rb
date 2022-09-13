# frozen_string_literal: true
require 'tenejo/pf_object'
require 'csv'
class Tenejo::Graph
  include ActiveModel::Serializers::JSON
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

  def attributes
    { works: [], collections: [], files: [], warnings: [], invalids: [], fatal_errors: [], root: {} }
  end

  def attributes=(hash)
    hash.each do |k, v|
      send("#{k}=", v)
    end
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
      @warnings << "Row #{lineno}: Unknown object type #{row[:object_type]}"
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
        @warnings << %/Row #{f.lineno}: Could not find parent work "#{f.parent}" for file "#{f.file}" - the file will be ignored/
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
        @warnings << %/Row #{f.lineno}: Could not find parent "#{f.parent}"; #{simple_class(f)} "#{f.identifier.first}" will be created without a parent if you continue./
        @root.children << f
      else
        @root.children << f
      end
    end
    self
  end

  def simple_class(pf_obj)
    case pf_obj
    when Tenejo::PFWork
      'work'
    when Tenejo::PFCollection
      'collection'
    else
      'unexpected class #{pf_obj.class}'
    end
  end

  def index(c, key: :identifier)
    c.index_by { |v| v.send(key).first; }
  end

  def reject_invalid
    @collections, invalid_collections = @collections.partition(&:valid?)
    @works, invalid_works = @works.partition(&:valid?)
    @files, invalid_files = @files.partition(&:valid?)
    @invalids = invalid_collections + invalid_works + invalid_files
    @warnings += @invalids.map { |k| "Row #{k.lineno}: #{k.errors.full_messages.join(', ')}" }

    all_the_items = @collections + @works + @files + @invalids
    @warnings += all_the_items.filter_map { |item| "Row #{item.lineno}: #{item.warnings.values.join(', ')}" if item.warnings.any? }
  end

  DEFAULT_UPLOAD_PATH = File.join(Hyrax.config.upload_path.call, 'ftp')
end
