# frozen_string_literal: true
# require './app/lib/tenejo/csv_importer'
require 'rails_helper'

RSpec.describe Tenejo::CsvImporter do
  collection1 = { identifier: 'C01', title: ['Collection No. 1'], description: ['Bits & bobs'] }
  collection2 = { identifier: 'C02', title: ['Collection No. 2'], description: ['Paper ephemera'] }
  job_graph = { collection: [collection1, collection2] }

  described_class.import(job_graph)
  persisted = Collection.find('C01')

  it 'creates a persistent collection' do
    expect(persisted).not_to be_nil
  end

  it 'creates collections with expected identifiers' do
    expect(persisted.id).to eq 'C01'
  end

  it 'sets #date_uploaded' do
    expect(persisted.date_uploaded.in_time_zone).to be_within(1.minute).of(Time.current)
  end

  it 'sets #date_modified to #date_uploaded' do
    expect(persisted.date_modified).to eq persisted.date_uploaded
  end

  it 'saves titles' do
    expect(Collection.where(title: 'Collection No. 2').count).to be >= 1
  end

  it 'saves optional fields', :aggregate_failures do
    expect(persisted.description).to include 'Bits & bobs'
  end
end
