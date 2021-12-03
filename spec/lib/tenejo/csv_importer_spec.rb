# frozen_string_literal: true
# require './app/lib/tenejo/csv_importer'
require 'rails_helper'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Tenejo::CsvImporter do
  before :context do
    graph = Tenejo::Preflight.read_csv(File.open("./spec/fixtures/csv/fancy.csv"))
    @fixture = graph[:collection].find { |x| x.identifier == "TESTINGCOLLECTION" }
    @fixture.identifier = Time.now.to_i.to_s # make sort of unique identifier
    described_class.import(graph)
    @persisted = Collection.find(@fixture.identifier)
  end
  after :context do
    @persisted.delete
  end
  it 'creates a persistent collection' do
    expect(@persisted).not_to be_nil
  end

  it 'creates collections with expected identifiers' do
    expect(@persisted.id).to eq @fixture.identifier
  end

  it 'sets #date_uploaded' do
    expect(@persisted.date_uploaded.in_time_zone).to be_within(1.minute).of(Time.current)
  end

  it 'sets #date_modified to #date_uploaded' do
    expect(@persisted.date_modified).to eq @persisted.date_uploaded
  end

  it 'saves titles' do
    expect(Collection.where(title: 'The testing collection').count).to be >= 1
  end
end
