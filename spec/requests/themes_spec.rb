# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/themes", type: :request do
  let(:valid_attributes) { Theme::DEFAULTS }
  let(:invalid_attributes) { { elephant: true } }

  let(:admin) { FactoryBot.create(:user, :admin) }
  before do
    sign_in admin
  end

  describe "GET /edit" do
    it "render a successful response" do
      get edit_theme_path
      expect(response).to be_successful
    end

    it 'renders in the dashboard layout' do
      get edit_theme_path
      expect(response).to render_template('layouts/hyrax/dashboard')
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      it "updates the requested theme" do
        theme = Theme.current_theme.reload
        patch theme_url, params: { theme: { site_title: 'Updated', background_color: '#F5F5F5' } }
        updated_theme = Theme.find(theme.id)
        expect(updated_theme.site_title).to eq 'Updated'
        expect(updated_theme.background_color).to eq '#F5F5F5'
      end

      it "redirects to the theme" do
        patch theme_url, params: { theme: { site_title: 'New site' } }
        expect(response).to redirect_to(edit_theme_path)
      end
    end

    it "resets to defaults", :aggregate_failures do
      patch theme_url, params: { theme: { site_title: "Not the default" } }
      expect(Theme.current_theme.site_title).to eq "Not the default"
      patch theme_url, params: { reset: "true", theme: { site_title: 'Tenejo' } }
      expect(Theme.current_theme.site_title).to eq "Tenejo"
    end

    it "applies defaults to the whole site", :aggregate_failures do
      ContentBlock.find_or_create_by(name: "header_background_color").update!(value: '#010101')
      new_color = '#0FF0FF88'
      patch theme_url, params: { theme: { primary_color: new_color } }
      patch theme_url, params: { apply: "true", theme: { site_title: 'Tenejo' } }
      background_color = ContentBlock.find_by(name: "header_background_color").value
      expect(background_color).to eq new_color
    end

    context "with invalid parameters" do
      it "are ignored" do
        patch theme_url, params: { theme: invalid_attributes }
        expect(response).to redirect_to(edit_theme_path)
      end
    end
  end
end
