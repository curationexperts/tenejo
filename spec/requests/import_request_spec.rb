# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/imports", type: :request do
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:admin) { User.create(email: 'test@example.com', password: '123456', roles: [Role.create(name: 'admin')]) }
  let(:preflight) { Preflight.create!(user: admin, manifest: tempfile) }
  let(:import) { Import.new(user: admin, parent_job: preflight, graph: Tenejo::Preflight.process_csv(preflight.manifest.download)) }

  before do
    sign_in admin
  end

  describe "GET /index" do
    it "redirects to /jobs/index" do
      get imports_path
      expect(response).to redirect_to jobs_path
    end
  end

  describe "GET /new" do
    it "redirects to /preflights/new" do
      get new_import_path
      expect(response).to redirect_to new_preflight_path
    end
  end

  describe "GET /show" do
    it "displays info for an Import job" do
      import.save!
      get import_path import
      expect(response).to render_template('imports/show')
    end
  end

  describe "POST /create" do
    it "creates a new Import job" do
      expect {
        post imports_path, params: { import: { parent_job_id: preflight.id } }
      }.to change(Import, :count).by(1)
    end

    it "queues a new IngestJob" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        post imports_path, params: { import: { parent_job_id: preflight.id } }
      } .to enqueue_job(BatchImportJob).with(Job.last).on_queue(:default)
    end

    it "redirects to the submitted Import show view" do
      post imports_path, params: { import: { parent_job_id: preflight.id } }
      expect(response).to redirect_to Import.last
    end

    it "sets status and item counts", :aggregate_failures do
      post imports_path, params: { import: { parent_job_id: preflight.id } }
      created_job = assigns(:job)
      expect(created_job.graph).not_to be_nil
      expect(created_job.status).to eq 'submitted'
      expect(created_job.created_at).to be_within(1.second).of Time.current
      expect(created_job.collections).to eq 0
      expect(created_job.works).to eq 0
      expect(created_job.files).to eq 0
    end
  end
end
