require 'rails_helper'
require './app/models/application_record'
require './app/models/user'
include Warden::Test::Helpers
RSpec.describe User do
  context "an admin user" do
    let(:user){
      described_class.find_or_create_by!(email: 'admin@example.com')do |u|
        u.password= 'passss'
        u.password_confirmation='passss'
      end
    }
    it "should have a role of admin" do
      expect(user.groups).to eq ["admin"]
    end

  end
end
