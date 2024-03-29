# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Theme, type: :model do
  it 'initializes with default values', :aggregate_failures do
    theme = described_class.new
    expect(theme.site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.hero_title).to eq Theme::DEFAULTS[:hero_title]
    expect(theme.hero_description).to eq Theme::DEFAULTS[:hero_description]
    expect(theme.primary_color).to eq Theme::DEFAULTS[:primary_color]
    expect(theme.accent_color).to eq Theme::DEFAULTS[:accent_color]
    expect(theme.primary_text_color).to eq Theme::DEFAULTS[:primary_text_color]
    expect(theme.accent_text_color).to eq Theme::DEFAULTS[:accent_text_color]
    expect(theme.background_color).to eq Theme::DEFAULTS[:background_color]
  end

  it 'does not overwrite explicit intiialization values', :aggregate_failures do
    theme = described_class.new(primary_color: '#ABCDEF')
    expect(theme.site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.hero_title).to eq Theme::DEFAULTS[:hero_title]
    expect(theme.hero_description).to eq Theme::DEFAULTS[:hero_description]
    expect(theme.primary_color).to eq '#ABCDEF'
  end

  it 'has a #current_theme class method' do
    expect(described_class.current_theme.id).to eq 1
  end

  it 'can .reset_preview_to_defaults', :aggregate_failures do
    theme = described_class.new(site_title: 'Not Your Average Default', primary_color: '#ABCDEF')
    expect(theme.site_title).to eq 'Not Your Average Default'
    expect(theme.primary_color).to eq '#ABCDEF'

    theme.reset_to_defaults

    expect(theme.preview_site_title).to eq Theme::DEFAULTS[:site_title]
    expect(theme.preview_primary_color).to eq Theme::DEFAULTS[:primary_color]
  end

  context '.apply_preview', :aggregate_failures do
    it 'updates main values from preview' do
      theme = described_class.new
      expect(theme.site_title).to eq 'Tenejo'
      expect(theme.primary_color).to eq '#000000'

      theme.preview_site_title = "New and Improved"
      theme.preview_primary_color = "DarkOliveGreen"
      theme.apply_preview

      expect(theme.site_title).to eq "New and Improved"
      expect(theme.primary_color).to eq "DarkOliveGreen"
    end

    it 'works on a persisted theme', :aggregate_failures do
      theme = described_class.current_theme

      theme.preview_site_title = "New and Improved"
      expect { theme.apply_preview }.not_to raise_error

      updated_theme = described_class.find(theme.id)
      expect(updated_theme.site_title).to eq "New and Improved"
    end
  end

  it 'has a default logo' do
    theme = described_class.new
    expect(theme.logo).to be_attached
  end

  it 'persists a new logo' do
    theme = described_class.find_or_create_by!(id: 1)
    # attach file
    logo = Rails.root.join('spec', 'fixtures', 'images', 'Noun Project Bank.png')
    theme.logo.attach(io: File.open(logo), filename: 'Noun Project Bank.png', content_type: 'image/png')
    theme.save!
    found_theme = described_class.find(theme.id)
    expect(found_theme.logo).to be_a_kind_of ActiveStorage::Attached::One
    expect(found_theme.logo.filename).to eq 'Noun Project Bank.png'
  end
end
