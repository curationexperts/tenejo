# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSet, type: :model do
  it 'can be indexed' do
    fs = described_class.new
    expect { fs.indexing_service.generate_solr_document }.not_to raise_error
  end
end
