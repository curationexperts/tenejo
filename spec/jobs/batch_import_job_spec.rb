# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchImportJob, type: :job do
  let(:user) { FactoryBot.create(:user) }
  describe "#perform_later" do
    it "queues" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        described_class.perform_later("filename")
      } .to have_enqueued_job.with("filename").on_queue(:default)
    end

    # rubocop:disable RSpec/MessageChain
    it "calls the importer with a graph made from a job" do
      # This test creates a fake preflight error which causes the fastest possible import
      ActiveJob::Base.queue_adapter = :test
      import_job = Import.create!(user: user)
      allow(import_job).to receive_message_chain('manifest.download') { 'csv placeholder' }
      allow(Tenejo::Preflight).to receive(:process_csv).and_return({ fatal_errors: ['No data was detected'] })
      described_class.perform_now(import_job)
      expect(Tenejo::Preflight).to have_received(:process_csv)
    end
  end
end
