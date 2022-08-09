# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/preflights", type: :request do
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:admin) { User.create(email: 'test@example.com', password: '123456', roles: [Role.create(name: 'admin')]) }
  let(:preflight) { Preflight.new(user: admin, manifest: tempfile) }

  before do
    sign_in admin
  end

  describe "GET /index" do
    it "redirects to /jobs/index" do
      preflight.save!
      get preflights_path
      expect(response).to redirect_to jobs_path
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_preflight_path
      expect(response).to render_template('preflights/new')
    end
  end

  describe "GET /show" do
    let(:valid_attributes) { { user: admin, manifest: tempfile } }
    let(:tempfile) { fixture_file_upload('csv/fancy.csv') }

    it "displays job summary and preflight info" do
      post preflights_path, params: { preflight: valid_attributes }
      get preflight_path Job.last
      expect(response).to render_template('preflights/show')
      expect(response.body).to match(/preflight-warnings/)
      expect(response.body).to match(/Could not find parent &quot;NONEXISTENT&quot;/)
    end
  end

  describe "POST /create" do
    before :all do
      FileUtils.mkdir_p('tmp/test/uploads/ftp')
      FileUtils.touch("tmp/test/uploads/ftp/MN-02 2.png")
      FileUtils.touch("tmp/test/uploads/ftp/MN-02 3.png")
      FileUtils.touch("tmp/test/uploads/ftp/MN-02 4.png")
    end
    let(:valid_attributes) { { user: admin, manifest: tempfile } }
    let(:tempfile) { fixture_file_upload('csv/fancy.csv') }

    context "with valid parameters" do
      it "creates a new Preflight job" do
        expect {
          post preflights_path, params: { preflight: valid_attributes }
        }.to change(Job, :count).by(1)
      end

      it "redirects to the created job" do
        post preflights_path, params: { preflight: valid_attributes }
        expect(response).to redirect_to(preflight_url(Job.last))
      end

      it "sets the collections, works, and jobs count", :aggregate_failures do
        post preflights_path, params: { preflight: valid_attributes }
        created_job = assigns(:job)
        expect(assigns(:graph)).not_to be_nil
        expect(created_job.status).to eq 'completed'
        expect(created_job.completed_at).to be_within(1.second).of Time.current
        expect(created_job.collections).to eq 2
        expect(created_job.works).to eq 4
        expect(created_job.files).to eq 4
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { field: 'invalid' } }
      it "does not create a new Job" do
        expect {
          post preflights_path, params: { preflight: invalid_attributes }
        }.to change(Job, :count).by(0)
      end

      it "(re)renders the 'new' template)" do
        post preflights_path, params: { preflight: invalid_attributes }
        expect(response).to be_unprocessable
        expect(response).to render_template('preflights/new')
      end
    end
  end
end
