# frozen_string_literal: true
class Theme < ApplicationRecord
  DEFAULTS = ActiveSupport::HashWithIndifferentAccess.new(
    site_title: 'Tenejo',
    hero_title: 'Welcome to Tenejo',
    hero_description: 'Digitized culturally significant library collections.',
    primary_color: '#000000',
    accent_color: '#C8512A',
    primary_text_color: '#1A1A1A',
    accent_text_color: '#C8512A',
    background_color: '#FFFFFF',
    preview_site_title: 'Tenejo',
    preview_hero_title: 'Welcome to Tenejo',
    preview_hero_description: 'Special Collections made simple',
    preview_primary_color: '#000000',
    preview_accent_color: '#C8512A',
    preview_primary_text_color: '#1A1A1A',
    preview_accent_text_color: '#C8512A',
    preview_background_color: '#FFFFFF'
    # logo: 'default_logo.png' # see ensure_logo below for logo attachment default
  ).freeze

  has_one_attached :logo
  has_one_attached :hero_image
  after_initialize :merge_defaults, :ensure_logo, :ensure_hero_image, :reset_preview_to_defaults

  def self.current_theme
    @current_theme ||= Theme.find_or_create_by(id: 1) do |theme|
      theme.merge_defaults
      theme.ensure_logo
      theme.ensure_hero_image
      theme.save
    end
  end

  def reset_to_defaults
    self.attributes = attributes.merge(DEFAULTS)
    reset_preview_to_defaults
    logo.purge
    hero_image.purge
    ensure_logo
    ensure_hero_image
    save if persisted?
  end

  def reset_preview_to_defaults
    self.preview_site_title = DEFAULTS[:site_title]
    self.preview_hero_title = DEFAULTS[:hero_title]
    self.preview_hero_description = DEFAULTS[:hero_description]
    self.preview_primary_color = DEFAULTS[:primary_color]
    self.preview_accent_color = DEFAULTS[:accent_color]
    self.preview_primary_text_color = DEFAULTS[:primary_text_color]
    self.preview_accent_text_color = DEFAULTS[:accent_text_color]
    self.preview_background_color = DEFAULTS[:background_color]
    save if persisted?
  end

  def apply_preview
    self.site_title = preview_site_title
    self.hero_title = preview_hero_title
    self.hero_description = preview_hero_description
    self.primary_color = preview_primary_color
    self.accent_color = preview_accent_color
    self.primary_text_color = preview_primary_text_color
    self.accent_text_color = preview_accent_text_color
    self.background_color = preview_background_color
    save if persisted?
  end

  def merge_defaults
    self.attributes = attributes.compact.reverse_merge(DEFAULTS)
  end

  def ensure_logo
    return if logo.attached?
    logo.attach(
      io: File.open('app/assets/images/default_logo.png'),
      filename: 'default_logo.png',
      content_type: 'image/svg+xml'
    )
    save if persisted?
  end

  def ensure_hero_image
    return if hero_image.attached?
    hero_image.attach(
      io: File.open('app/assets/images/default_hero.jpg'),
      filename: 'default_hero.jpg',

      content_type: 'image/jpg'
    )
    save if persisted?
  end
end
