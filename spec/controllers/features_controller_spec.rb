# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::StrategiesController, type: :controller do
  routes { Hyrax::Engine.routes }
  let(:strategy) { Flipflop::FeatureSet.current.test! }
  context "logged in as admin" do
    login_admin
    it "turns toggle registerable module feature, and remove routese" do
      routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
      expect(routes).not_to include '/users/sign_up(.:format)'
      expect(Devise.mappings[:user].registerable?).to eq false
      put :update, params: { feature_id: "self_register", id: strategy.key, commit: "on" }
      expect(Devise.mappings[:user].registerable?).to eq true

      newroutes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
      expect(newroutes).to include '/users/sign_up(.:format)'

      expect(Devise.mappings[:user].registerable?).to eq true
      put :update, params: { feature_id: "self_register", id: strategy.key, commit: "on" }
      expect(Devise.mappings[:user].registerable?).to eq false
      routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
      expect(routes).not_to include '/users/sign_up(.:format)'
    end
  end

  context "not logged in at all" do
    it "does not let you in" do
      put :update, params: { feature_id: "self_register", id: strategy.key, commit: "on" }
      expect(controller.current_user).to be_nil
      expect(flash[:alert]).to eq "You are not authorized to access this page."
      expect(response.status).to redirect_to("/users/sign_in?locale=en")
    end
  end
  context "logged in as admin user" do
    login_user
    it "does not let you in either" do
      put :update, params: { feature_id: "self_register", id: strategy.key, commit: "on" }
      expect(controller.current_user).not_to be_nil
      expect(response.status).to redirect_to("/?locale=en")
      expect(flash[:alert]).to eq "You are not authorized to access this page."
    end
  end
end
