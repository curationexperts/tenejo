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

  describe "POST /create" do
    let(:valid_attributes) { { user: admin, manifest: tempfile } }
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
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { field: 'invalid' } }
      it "does not create a new Job" do
        expect {
          post preflights_path, params: { preflight: invalid_attributes }
        }.to change(Job, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post preflights_path, params: { preflight: invalid_attributes }
        expect(response).to be_unprocessable
        expect(response).to render_template('preflights/new')
      end
    end
  end
end
