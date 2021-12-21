# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { described_class.create(email: 'teat1234@example.com', password: '654321') }
  let!(:job) { Job.create(user: user) }

  it 'can have associated jobs', :aggregate_failures do
    expect(user.jobs).to include job
    expect(job.user).to eq user
  end

  it "soft destroys" do
    expect(user.deactivated?).to be false
    user.destroy
    expect(described_class.find(user.id)).not_to be nil
    expect(user.active_for_authentication?).to be false
  end

  it "can be disabled" do
    expect(user.deactivated?).to be false
    expect(user.active_for_authentication?).to be true
    user.deactivated = true
    user.save!
    expect(user.active_for_authentication?).to be false
  end
end
