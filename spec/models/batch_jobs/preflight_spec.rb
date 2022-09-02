# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Preflight, type: :model do
  let(:user) { FactoryBot.create(:user) }

  it 'inherits .type via STI' do
    job = described_class.new
    expect(job.type).to eq 'Preflight'
  end

  it 'requires a file' do
    job = described_class.new(user: user)
    expect { job.save! }.to raise_exception(ActiveRecord::RecordInvalid, /Manifest must be attached/)
  end

  it 'persists the associated file' do
    job = described_class.new(user: user)
    # attach file
    empty_csv = Rails.root.join('spec', 'fixtures', 'csv', 'empty.csv')
    job.manifest.attach(io: File.open(empty_csv), filename: 'empty.csv', content_type: 'text/csv')
    job.save!
    found_job = described_class.find(job.id)
    expect(found_job.manifest).to be_a_kind_of ActiveStorage::Attached::One
    expect(found_job.manifest.filename).to eq 'empty.csv'
  end
end
