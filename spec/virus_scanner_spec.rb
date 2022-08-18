# frozen_string_literal: true

require 'rails_helper'
require './app/lib/tenejo/virus_scanner'

RSpec.describe Tenejo::VirusScanner do
  context "with clean file" do
    let(:scanner) {Tenejo::VirusScanner.new('./spec/fixtures/images/cat.jpg', "clamscan")}
    it "does not freak out" do
      expect(scanner.infected?).to be false
    end
  end
  context "with nonexistent file" do
    let(:scanner) {Tenejo::VirusScanner.new('nofile', "clamscan")}
    it "raises" do
      expect { scanner.infected? }.to raise_error Exception
    end
  end
  context "with virus file" do
    let(:scanner) { Tenejo::VirusScanner.new('./spec/fixtures/virus_check.txt', "clamscan") }
    it "freaks out" do
      expect(scanner.infected?).to be_truthy
    end
  end
end
