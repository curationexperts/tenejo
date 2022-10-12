# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "shared/_footer", type: :view do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:footer_version, true)
  end
  context "on prod-like servers" do
    # Assumes that prod-like servers have an environment name separated by a dash in the hostname\
    # See FooterHelper for details
    it 'displays detailed git information' do
      controller.request.host = 'prod-like.example.com'
      render
      expect(rendered).to have_selector('.version', text: "SHA")
    end
  end

  context "on production servers" do
    # Assumes that production servers do not have dashed in hostnames
    it 'displays only version info' do
      controller.request.host = 'production.example.com'
      render
      expect(rendered).to have_selector('.version', text: "Unknown branch")
      expect(rendered).to have_no_selector('.version', text: "SHA")
    end
  end

  context "on local development and test environments" do
    it 'displays detailed git information' do
      controller.request.host = 'localhost'
      render
      expect(rendered).to have_selector('.version', text: "SHA")
    end
  end
end
