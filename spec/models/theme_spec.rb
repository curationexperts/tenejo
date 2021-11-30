# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Theme, type: :model do
  it 'initializes with default values', :aggregate_failures do
    theme = described_class.new
    expect(theme.site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.primary_color).to eq Theme::DEFAULTS[:primary_color]
    expect(theme.accent_color).to eq Theme::DEFAULTS[:accent_color]
    expect(theme.primary_text_color).to eq Theme::DEFAULTS[:primary_text_color]
    expect(theme.accent_text_color).to eq Theme::DEFAULTS[:accent_text_color]
    expect(theme.background_color).to eq Theme::DEFAULTS[:background_color]
  end

  it 'does not overwrite explicit intiialization values', :aggregate_failures do
    theme = described_class.new(primary_color: '#ABCDEF')
    expect(theme.site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.primary_color).to eq '#ABCDEF'
  end

  it 'has a #current_theme class method' do
    expect(described_class.current_theme.id).to eq 1
  end

  it 'can .reset_to_defaults', :aggregate_failures do
    theme = described_class.new(site_title: 'Not Your Average Default', primary_color: '#ABCDEF')
    expect(theme.site_title).to eq 'Not Your Average Default'
    expect(theme.primary_color).to eq '#ABCDEF'

    theme.reset_to_defaults

    expect(theme.site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.primary_color).to eq Theme::DEFAULTS[:primary_color]
  end
end
