# frozen_string_literal: true
require "rails_helper"

RSpec.describe ThemesController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/theme/edit").to route_to("themes#edit")
    end

    it "routes to #update via PUT" do
      expect(put: "/theme").to route_to("themes#update")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/theme").to route_to("themes#update")
    end
  end

  describe "un-routable" do
    it "#edit individual themes" do
      expect(get: "/themes/edit/1").not_to be_routable
    end

    it "#update individual themes via PUT" do
      expect(put: "/themes/1").not_to be_routable
    end

    it "#update individual themes via PATCH" do
      expect(patch: "/themes/1").not_to be_routable
    end

    it "routes to #index" do
      expect(get: "/theme").not_to be_routable
    end

    it "routes to #new" do
      expect(get: "/themes/new").not_to be_routable
    end

    it "routes to #show" do
      expect(get: "/themes/1").not_to be_routable
    end

    it "routes to #create" do
      expect(post: "/themes").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/themes/1").not_to be_routable
    end
  end
end
