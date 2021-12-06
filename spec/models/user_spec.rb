# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { described_class.create(email: 'teat1234@example.com', password: '654321') }
  let!(:job) { Job.create(user: user) }

  it 'can have associated jobs', :aggregate_failures do
    expect(user.jobs).to include job
    expect(job.user).to eq user
  end

  it 'is protected from deletion if the user has jobs', :aggregate_failures do
    expect { user.destroy! }.to raise_exception(ActiveRecord::RecordNotDestroyed)
    expect(user.errors.messages[:base]).to include('Cannot delete record because dependent jobs exist')
  end
end
