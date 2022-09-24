# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSet, type: :model do
  it 'can be indexed' do
    fs = described_class.new
    expect { fs.indexing_service.generate_solr_document }.not_to raise_error
  end

  it 'does not tokenize identifier' do
    fs = described_class.new(identifier: "TESTING-123")
    solr_doc = fs.indexing_service.generate_solr_document
    expect(solr_doc.keys).to include "identifier_ssi"
    expect(solr_doc["identifier_ssi"]).to eq "TESTING-123"
  end
end
