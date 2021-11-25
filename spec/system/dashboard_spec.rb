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

    it 'has a user profile section' do
      expect(page).to have_selector('#user-profile')
    end

    it 'restricts admin-only menus' do
      expect(page).to have_no_selector('#dashboard-sidebar-jobs')
    end
  end

  context 'for admin users' do
    before do
      sign_in admin
      visit('dashboard')
    end

    it 'displays a jobs menu' do
      expect(page).to have_selector('#dashboard-sidebar-jobs')
    end

    it 'has a sidekiq link' do
      expect(page).to have_link(href: sidekiq_dashboard_path)
    end

    # We need an engine routing test because Hrax namespaced controllers
    # don't access tenejo routes as expected
    it 'allows Hyrax controllers to access tenejo paths' do
      sign_in admin
      expect { visit('dashboard/my/works') }.not_to raise_exception
      expect(page).to have_link('dashboard-sidebar-job-status')
    end

    it 'has a link to job statuses' do
      expect(page).to have_link(href: '/jobs')
    end
  end
end
