# frozen_string_literal: true
require "rails_helper"

describe FooterHelper do
  describe '#production_host?' do
    it 'returns true for hosts without a hyphen in their name' do
      controller.request.host = 'production.example.com'
      expect(helper.production_host?).to eq true
    end
    it 'returns false for localhost' do
      controller.request.host = 'localhost'
      expect(helper.production_host?).to eq false
    end
    it 'returns false for hosts with a hyphen in their name' do
      controller.request.host = 'prod-like.example.com'
      expect(helper.production_host?).to eq false
    end
  end
end
