# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Work do
  it '::metadata returns all fields' do
    expect(described_class.terms).to include(:description)
    expect(described_class.terms).not_to include(:fuel_injector_count)
  end

  it '::required_metadata returns required fields' do
    expect(described_class.required_terms).to include(:title)
    expect(described_class.required_terms).not_to include(:description)
  end

  it '::editable_metadata lists user editable fields' do
    expect(described_class.editable_terms).to include(:creator)
    expect(described_class.editable_terms).not_to include(:date_uploaded)
  end

  context 'indexing' do
    let(:work) {
      described_class.new(
      identifier:       'TESTING-123',
      date_normalized:  '1954-03-26',
      date_created:     'March 26, 1954',
      date_copyrighted: '1954',
      date_issued:      '1955-02-09',
      date_accepted:    '1982-04-30',
      date_uploaded:    Date.parse('1954-11-12').to_time.utc,
      date_modified:    Date.parse('1999-05-29').to_time.utc,
      resource_type:    ['Book'],
      resource_format:  ['Trade Paperback', 'Paperback'],
      genre:            ['Science Fiction', 'Post-Apocalyptic'],
      extent:           ['238 pages']
    )
    }
    let(:solr_doc) { work.indexing_service.generate_solr_document }

    it 'does not tokenize identifier' do
      expect(solr_doc.keys).to include "identifier_ssi"
      expect(solr_doc["identifier_ssi"]).to eq "TESTING-123"
    end

    it 'includes dates', :aggregate_failures do
      expect(solr_doc.keys).to include('date_normalized_ssi', 'date_created_ssi', 'date_copyrighted_ssi', 'date_issued_ssi',
                                       'date_accepted_ssi', 'date_uploaded_dtsi', 'date_modified_dtsi')
      expect(solr_doc['date_normalized_ssi']).to match(/1954-03-26/)
      expect(solr_doc['date_created_ssi']).to eq 'March 26, 1954'
      expect(solr_doc['date_copyrighted_ssi']).to eq '1954'
      expect(solr_doc['date_issued_ssi']).to eq '1955-02-09'
      expect(solr_doc['date_accepted_ssi']).to eq '1982-04-30'
      expect(solr_doc['date_uploaded_dtsi']).to match(/1954-11-12/)
      expect(solr_doc['date_modified_dtsi']).to match(/1999-05-29/)
    end

    it 'includes format' do
      expect(solr_doc.keys).to include('resource_format_tesim')
      expect(solr_doc['resource_format_tesim']).to include 'Trade Paperback' # searchable
      expect(solr_doc['resource_format_sim']).to include 'Paperback' # facetable
    end

    it 'includes genre' do
      expect(solr_doc.keys).to include('genre_tesim')
      expect(solr_doc['genre_tesim']).to contain_exactly 'Science Fiction', 'Post-Apocalyptic'
      expect(solr_doc['genre_sim']).to   contain_exactly 'Science Fiction', 'Post-Apocalyptic'
    end

    it 'includes extent' do
      expect(solr_doc.keys).to include('extent_tesim')
      expect(solr_doc['extent_tesim']).to eq ['238 pages']
      expect(solr_doc['extent_sim']).to   eq ['238 pages']
    end
  end
end
