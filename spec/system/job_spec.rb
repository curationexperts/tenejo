# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'jobs dashboard', type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:user) { User.new(email: 'user@example.com') }
  let(:admin) { User.new(email: 'admin@example.com', roles: [admin_role]) }
  let(:admin_role) { Role.new(name: 'admin') }

  context 'restricts non-admin users' do
    it 'redirects guests to login' do
      visit jobs_url
      expect(page.current_path).to eq new_user_session_path
    end

    it 'gives non-admins an "unauthorized" error' do
      sign_in user
      visit jobs_url
      expect(page).to have_text "You are not authorized to access this page."
    end
  end

  context 'allows admin users' do
    it 'view the jobs status page' do
      sign_in admin
      visit jobs_url
      expect(page.current_path).to eq jobs_path
      expect(page).to have_selector('tr th', text: 'Type')
    end
  end
end
