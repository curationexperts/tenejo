# frozen_string_literal: true
require 'rails_helper'
require 'tenejo/graph'

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
      graph = Tenejo::Graph.new
      graph.add_fatal_error('No data was detected')
      import_job = Import.create!(user: user)
      import_job.graph = graph
      import_job.save!
      described_class.perform_now(import_job)
    end
  end
end
