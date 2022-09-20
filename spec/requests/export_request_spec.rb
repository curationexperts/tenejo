# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/exports", type: :request do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:export) { Export.new(user: admin, graph: Tenejo::Graph.new) }

  before do
    sign_in admin
  end

  describe "GET /index" do
    it "redirects to /jobs/index" do
      get exports_path
      expect(response).to redirect_to jobs_path
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_export_path
      expect(response).to render_template('exports/new')
    end
  end

  describe "GET /show" do
    it "displays info for an export job" do
      export.save!
      get export_path export
      expect(response).to render_template('exports/show')
    end
  end

  describe "POST /create" do
    it "creates a new export job" do
      expect {
        post exports_path, params: { export: { identifiers: [] } }
      }.to change(Export, :count).by(1)
    end

    it "queues a new background job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        post exports_path, params: { export: { identifiers: [] } }
      } .to enqueue_job(BatchExportJob).with(Job.last).on_queue(:default)
    end

    it "redirects to the submitted export show view" do
      post exports_path, params: { export: { identifiers: [] } }
      expect(response).to redirect_to Export.last
    end

    it "omits blank identifiers" do
      # Check that we ignore empty strings, nil, and things that evaluate to either
      post exports_path, params: { export: { identifiers: ["", nil, "DummyID", %q(), {}[:field]] } } # rubocop:disable Style/RedundantPercentQ
      expect(Export.last.identifiers).to eq ['DummyID']
    end
  end
end
