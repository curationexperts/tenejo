# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::StrategiesController, type: :controller do
  routes { Hyrax::Engine.routes }
  let(:strategy) { Flipflop::FeatureSet.current.test! }
  context "logged in as admin" do
    login_admin
    it "turns toggle registerable module feature, and remove routese" do
      put :update, params: { feature_id: "proxy_deposit", id: strategy.key, commit: "off" }
      expect(response.status).to redirect_to admin_features_path
    end
  end

  context "not logged in at all" do
    it "does not let you in" do
      put :update, params: { feature_id: "proxy_deposit", id: strategy.key, commit: "on" }
      expect(controller.current_user).to be_nil
      expect(flash[:alert]).to eq "You are not authorized to access this page."
      expect(response.status).to redirect_to("/users/sign_in?locale=en")
    end
  end
  context "logged in as admin user" do
    login_user
    it "does not let you in either" do
      put :update, params: { feature_id: "proxy_deposit", id: strategy.key, commit: "on" }
      expect(controller.current_user).not_to be_nil
      expect(response.status).to redirect_to("/?locale=en")
      expect(flash[:alert]).to eq "You are not authorized to access this page."
    end
  end
end
