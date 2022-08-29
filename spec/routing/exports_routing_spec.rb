# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExportsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/exports").to route_to("exports#index")
    end

    it "routes to #new" do
      expect(get: "/exports/new").to route_to("exports#new")
    end

    it "routes to #show" do
      expect(get: "/exports/1").to route_to("exports#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/exports").to route_to("exports#create")
    end

    # Preflight jobs are not editable after creation
    context 'invalid routes' do
      it "does not route to #edit" do
        expect(get: "/exports/1/edit").not_to be_routable
      end

      it "does not route to #update via PUT" do
        expect(put: "/exports/1").not_to be_routable
      end

      it "does not route to #update via PATCH" do
        expect(patch: "/exports/1").not_to be_routable
      end

      it "does not route to #destroy" do
        expect(delete: "/exports/1").not_to be_routable
      end
    end
  end
end
