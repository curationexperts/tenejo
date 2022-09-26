# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'hyrax/base/attribute_rows', type: :view do
  let(:solr_document) do
    SolrDocument.new(has_model_ssim: 'GenericWork',
                     date_normalized_dtsi: DateTime.new(1999, 0o1, 30).to_s,
                     date_created_ssi: 'Nineteen-Hundred and Nienty-Nine',
                     date_copyrighted_ssi: '1999',
                     date_issued_ssi: 'May 3, 1999',
                     date_accepted_ssi: DateTime.parse('June 20, 1999 3:05p CDT').inspect,
                     resource_type_tesim: ['Map'],
                     resource_format_tesim: ['polar projection'],
                     genre_tesim: ['satellite imagery', 'false color'],
                     extent_tesim: ['24 x 38 inches', '2 sheets'])
  end
  let(:ability) { double }
  let(:presenter) { Hyrax::WorkPresenter.new(solr_document, ability) }

  it 'displays dates', :aggregate_failures do
    render 'hyrax/base/attribute_rows', presenter: presenter
    expect(rendered).to have_selector('.attribute-date_created', text: 'Nineteen-Hundred and Nienty-Nine')
    expect(rendered).to have_selector('.attribute-date_copyrighted', text: '1999')
    expect(rendered).to have_selector('.attribute-date_issued', text: 'May 3, 1999')
    expect(rendered).to have_selector('.attribute-date_accepted', text: 'Sun, 20 Jun 1999')
  end

  it 'displays genre and related fields', :aggregate_failures do
    render 'hyrax/base/attribute_rows', presenter: presenter
    expect(rendered).to have_selector('.attribute-resource_type', text: 'Map')
    expect(rendered).to have_selector('.attribute-resource_format', text: 'polar projection')
    expect(rendered).to have_selector('.attribute-genre', text: 'false color')
    expect(rendered).to have_selector('.attribute-extent', text: '2 sheets')
  end
end
