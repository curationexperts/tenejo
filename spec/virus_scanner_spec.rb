# frozen_string_literal: true

require 'rails_helper'
require './app/lib/tenejo/virus_scanner'

RSpec.describe Tenejo::VirusScanner do
  context "with clean file" do
    let(:goodfile) { './spec/fixtures/images/cat.jpg' }
    it "does not freak out" do
      expect(described_class.new(goodfile).infected?).to be false
    end
  end
  context "with nonexistent file" do
    let(:badfile) { './nothere' }
    before do
      allow(Clamby).to receive(:virus?).and_raise(Clamby::FileNotFound)
    end
    it "raises" do
      expect { described_class.new(badfile).infected? }.to raise_error Clamby::FileNotFound
    end
  end
  context "with virus file" do
    let(:badfile) { './spec/fixtures/virus_check.txt' }
    before do
      allow(Clamby).to receive(:virus?).and_return(true)
    end

    it "freaks out" do
      expect(described_class.new(badfile).infected?).to be_truthy
    end
  end
end
