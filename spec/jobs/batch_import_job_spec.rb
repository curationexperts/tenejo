# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchImportJob, type: :job do
  describe "#perform_later" do
    it "queues" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        described_class.perform_later("filename")
      } .to have_enqueued_job.with("filename").on_queue(:default)
    end
    it "calls the importer with a graph made from a file" do
      ActiveJob::Base.queue_adapter = :test
      allow(Tenejo::CsvImporter).to receive(:import)
      allow(Tenejo::Preflight).to receive(:process_csv).and_return "some graph"
      described_class.perform_now(Rails.root.join("spec/fixtures/csv/fancy.csv"))
      expect(Tenejo::CsvImporter).to have_received(:import).with("some graph")
      expect(Tenejo::Preflight).to have_received(:process_csv)
    end
  end
end
