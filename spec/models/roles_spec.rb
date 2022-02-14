# frozen_string_literal: true
require "rails_helper"

RSpec.describe Role, type: :model do
  context "a role" do
    let(:role) { described_class.create!(name: "foo bar baz") }
    it "orders them in reverse chronologically" do
      expect(role).not_to be_nil
      expect(role.name).to eq "foo bar baz"
    end
    it "does not allow duplicate names" do
      r = described_class.new(name: role.name)
      expect(r.save).not_to be true
      expect(r.errors[:name]).to eq ["has already been taken"]
    end
  end

  context "an admin role" do
    let(:role) { described_class.create!(name: "admin") }
    it "does now allow deletion" do
      expect(role.destroy).to eq false
      expect(role.errors[:base]).to eq ["is indestructible"]
    end
  end
end
