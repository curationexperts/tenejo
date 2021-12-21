# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/user", type: :request do
  context "not logged in" do
    it "redirects" do
      get checks_path
      expect(response).to redirect_to new_user_session_path
    end
  end
  context "logged in as admin" do
    let(:admin) { User.create(email: 'test@example.com', password: '123456', roles: [Role.create(name: 'admin')]) }
    let(:user) { FactoryBot.create(:user) }
    before do
      sign_in admin
    end

    describe "deactivate" do
      it "renders a successful response" do
        put user_path(user.id, deactivated: true)
        expect(response).to redirect_to(hyrax.admin_users_path)
        expect(flash[:notice]).to eq "User deactivated"
      end
    end
    describe "activate" do
      it "renders a successful response" do
        put user_path(user.id, deactivated: false)
        expect(response).to redirect_to(hyrax.admin_users_path)
        expect(flash[:notice]).to eq "User reactivated"
      end
    end
  end
end
