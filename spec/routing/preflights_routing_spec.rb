# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreflightsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/preflights").to route_to("preflights#index")
    end

    it "routes to #new" do
      expect(get: "/preflights/new").to route_to("preflights#new")
    end

    it "routes to #show" do
      expect(get: "/preflights/1").to route_to("preflights#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/preflights").to route_to("preflights#create")
    end

    # Preflight jobs are not editable after creation
    context 'invalid routes' do
      it "does not route to #edit" do
        expect(get: "/preflights/1/edit").not_to be_routable
      end

      it "does not route to #update via PUT" do
        expect(put: "/preflights/1").not_to be_routable
      end

      it "does not route to #update via PATCH" do
        expect(patch: "/preflights/1").not_to be_routable
      end

      it "does not route to #destroy" do
        expect(delete: "/preflights/1").not_to be_routable
      end
    end
  end
end
