# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/checks", type: :request do
  context "not logged in" do
    it "redirects" do
      get checks_path
      expect(response).to redirect_to new_user_session_path
    end
  end
  context "logged in as admin" do
    let(:admin) { User.create(email: 'test@example.com', password: '123456', roles: [Role.create(name: 'admin')]) }
    before do
      sign_in admin
    end

    describe "GET /index" do
      it "renders a successful response" do
        get checks_path
        expect(response).to be_successful
        expect(assigns(:results)).not_to be_nil
        expect(response).to render_template('layouts/hyrax/dashboard')
      end
    end
  end
end
