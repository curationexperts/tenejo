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
end
