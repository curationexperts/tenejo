# frozen_string_literal: true

require 'rails_helper'
require './app/lib/virus_scanner'

RSpec.describe Cur::VirusScanner do
  context "with clean file" do
    let(:goodfile) { './spec/fixtures/images/cat.jpg' }
    it "does not freak out" do
      expect(described_class.new(goodfile).infected?).to be false
    end
  end
  context "with nonexistent file" do
    let(:badfile) { './nothere' }
    it "raises" do
      expect { described_class.new(badfile).infected? }.to raise_error Clamby::FileNotFound
    end
  end
  context "with virus file" do
    let(:badfile) { './spec/fixtures/virus_check.txt' }
    it "freaks out" do
      expect(described_class.new(badfile).infected?).to be_truthy
    end
  end
end
