# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Export, type: :model do
  let(:user) { FactoryBot.create(:user) }

  it 'inherits .type via STI' do
    job = described_class.new
    expect(job.type).to eq 'Export'
  end

  context '#identifiers' do
    it 'initializes to an empty array' do
      export = described_class.new
      expect(export.identifiers).to eq []
    end

    it 'behaves like an array' do
      export = described_class.new
      expect(export.identifiers).to be_a_kind_of Array
    end

    it 'can be persisted' do
      export = described_class.new(user: user)
      export.identifiers = ['first', 'second']
      export.save!
      export.identifiers = ['third']
      expect(export.identifiers).to eq ['third']
      export.reload
      expect(export.identifiers).to eq ['first', 'second']
    end
  end

  context 'file attachment' do
    it 'is optional' do
      export = described_class.new(user: user)
      expect { export.save! }.not_to raise_error
    end

    it 'can be persisted' do
      export = described_class.new(user: user)
      # attach file
      empty_csv = Rails.root.join('spec', 'fixtures', 'csv', 'empty.csv')
      export.manifest.attach(io: File.open(empty_csv), filename: 'empty.csv', content_type: 'text/csv')
      export.save!
      found_job = described_class.find(export.id)
      expect(found_job.manifest).to be_a_kind_of ActiveStorage::Attached::One
      expect(found_job.manifest.filename).to eq 'empty.csv'
    end
  end
end
