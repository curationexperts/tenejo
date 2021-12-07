# frozen_string_literal: true
require "rails_helper"

RSpec.describe JobsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/jobs").to route_to("jobs#index")
    end

    it "routes to #new" do
      expect(get: "/jobs/new").to route_to("jobs#new")
    end

    it "routes to #show" do
      expect(get: "/jobs/1").to route_to("jobs#show", id: "1")
    end
  end

  # Only job subclasses should be persisted to the database and
  # Jobs are not currently modifiable via the UI after creation
  describe "invalid routes" do
    it "routes to #edit" do
      expect(get: "/jobs/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(post: "/jobs").not_to be_routable
    end

    it "routes to #update via PUT" do
      expect(put: "/jobs/1").not_to be_routable
    end

    it "routes to #update via PATCH" do
      expect(patch: "/jobs/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/jobs/1").not_to be_routable
    end
  end
end
