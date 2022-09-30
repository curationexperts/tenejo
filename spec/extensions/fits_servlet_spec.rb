# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hydra::FileCharacterization::Characterizers::FitsServlet do
  if ENV['FITS_SERVLET_URL'] # don't run unless we have a fits env
    it 'can handle files with commas' do
      filename = "this, terrible, filename.txt"
      FileUtils.touch filename
      system(described_class.new(filename).send(:command), exception: true)
      FileUtils.rm filename
    end
    it 'can handle files with quotes' do
      filename = "this', terrible, 'filename.txt"
      FileUtils.touch filename
      system(described_class.new(filename).send(:command), exception: true)
      FileUtils.rm filename
    end
    it 'can handle paths with quotes' do
      dirname = "la 'fool,"
      filename = "ee'this', terrible, 'filename.txt"
      FileUtils.mkdir dirname
      FileUtils.touch filename
      system(described_class.new(filename).send(:command), exception: true)
      FileUtils.rm filename
      FileUtils.rmdir dirname
    end
    it 'can handle this in particular' do
      dirname = "foo/"
      filename = "Bussey Master's Thesis.pdf"
      FileUtils.mkdir dirname
      FileUtils.touch filename
      system(described_class.new(filename).send(:command), exception: true)
      FileUtils.rm filename
      FileUtils.rmdir dirname
    end
  end
end
