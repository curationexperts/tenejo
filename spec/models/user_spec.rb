# frozen_string_literal: true

require 'rails_helper'
require './app/models/application_record'
require './app/models/user'
RSpec.describe User do
  include Warden::Test::Helpers
  context 'an admin user' do
    let(:user) do
      described_class.find_or_create_by!(email: 'admin@example.com') do |u|
        u.password = 'passss'
        u.password_confirmation = 'passss'
      end
    end
    it 'should have a role of admin' do
      expect(user.groups).to eq ['admin']
    end
  end
end
