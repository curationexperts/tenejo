# frozen_string_literal: true

require 'rails_helper'
require './app/lib/tenejo/virus_scanner'

RSpec.describe Tenejo::VirusScanner do
  executable = ENV.fetch('CLAMSCAN_EXEC', "clamscan")
  context "with clean file" do
    let(:scanner) { described_class.new('./spec/fixtures/images/cat.jpg', executable) }
    it "does not freak out" do
      expect(scanner.infected?).to be false
    end
  end
  context "with strange file" do
    let(:filename) { "tmp/foobar, ' baz.txt" }
    before do
      FileUtils.touch(filename)
    end
    after do
      FileUtils.rm(filename)
    end
    let(:scanner) { described_class.new(filename, executable) }
    it "does not freak out about quotes and commas" do
      expect(scanner.infected?).to be false
    end
  end
  context "with nonexistent file" do
    let(:scanner) { described_class.new('nofile', executable) }
    it "raises" do
      expect { scanner.infected? }.to raise_error Exception
    end
  end
  context "with virus file" do
    let(:scanner) { described_class.new('./spec/fixtures/virus_check.txt', executable) }
    it "freaks out" do
      expect(scanner.infected?).to be_truthy
    end
  end
end
