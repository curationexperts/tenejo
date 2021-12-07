# frozen_string_literal: true
require "rails_helper"

RSpec.describe ImportsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/imports").to route_to("imports#index")
    end

    it "routes to #new" do
      expect(get: "/imports/new").to route_to("imports#new")
    end

    it "routes to #show" do
      expect(get: "/imports/1").to route_to("imports#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/imports").to route_to("imports#create")
    end

    # Preflight jobs are not editable after creation
    context 'invalid routes' do
      it "does not route to #edit" do
        expect(get: "/imports/1/edit").not_to be_routable
      end

      it "does not route to #update via PUT" do
        expect(put: "/imports/1").not_to be_routable
      end

      it "does not route to #update via PATCH" do
        expect(patch: "/imports/1").not_to be_routable
      end

      it "does not route to #destroy" do
        expect(delete: "/imports/1").not_to be_routable
      end
    end
  end
end
