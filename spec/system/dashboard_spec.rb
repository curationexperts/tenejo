# frozen_string_literal: true
require 'rails_helper'

# TODO: investigate turning this into a view spec
RSpec.describe 'dashboard' do
  before do
    driven_by(:rack_test)
  end

  let(:user) { User.new(email: 'user@example.com') }
  let(:admin) { User.new(email: 'admin@example.com', roles: [admin_role]) }
  let(:admin_role) { Role.new(name: :admin) }

  context 'for guest users' do
    it 'redirects to login' do
      visit('dashboard')
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'for regular users' do
    before do
      sign_in user
      visit('dashboard')
    end

    it 'has a "Repository Contents" section' do
      expect(page).to have_selector('#content-wrapper div.sidebar nav ul li', text: /Repository Contents/i)
    end

    it 'restricts admin-only sections' do
      expect(page).not_to have_selector('#content-wrapper div.sidebar nav ul li', text: /Tasks/i)
    end
  end

  context 'for admin users' do
    before do
      sign_in admin
      visit('dashboard')
    end

    it 'displays admin-only sections' do
      expect(page).to have_selector('#content-wrapper div.sidebar nav ul li', text: 'Tasks')
    end

    it 'displays a jobs menu' do
      pending 'needs job controller implementation'
      expect(page).to have_selector('#sidebar_jobs_menu')
    end
  end
end
