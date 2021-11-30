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
      let(:new_attributes) { { site_title: 'Updated', background_color: '#F5F5F5' } }

      it "updates the requested theme" do
        theme = Theme.current_theme.reload
        patch theme_url(theme), params: { theme: new_attributes, format: 'html' }
        updated_theme = Theme.find(theme.id)
        expect(updated_theme.site_title).to eq 'Updated'
        expect(updated_theme.background_color).to eq '#F5F5F5'
      end

      it "redirects to the theme" do
        theme = Theme.current_theme
        patch theme_url(theme), params: { theme: new_attributes }
        expect(response).to redirect_to(edit_theme_path)
      end
    end

    context "with invalid parameters" do
      it "are ignored" do
        theme = Theme.current_theme
        patch theme_url(theme), params: { theme: invalid_attributes }
        expect(response).to redirect_to(edit_theme_path)
      end
    end
  end
end
