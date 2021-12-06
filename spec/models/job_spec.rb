# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Job, type: :model do
  let(:user) { FactoryBot.create(:user) }

  it 'does not have a default user' do
    job = described_class.new
    expect(job.user).to be_nil
  end

  it 'cannot be saved without a valid user' do
    job = described_class.new
    expect { job.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User must exist')
  end

  it 'saves with a valid user' do
    job = described_class.new(user: user)
    expect { job.save! }.not_to raise_error
    job.reload
    expect(job.user).to eq user
  end

  it 'has an optional parent_job' do
    job1 = described_class.new(user: user)
    job2 = described_class.new(user: user)
    job2.parent_job = job1
    job2.save!
    expect(job1.child_jobs).to include job2
  end
end
