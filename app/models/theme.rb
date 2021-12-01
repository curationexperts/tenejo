# frozen_string_literal: true
class Theme < ApplicationRecord
  DEFAULTS = ActiveSupport::HashWithIndifferentAccess.new(
    site_title: 'Tenejo',
    primary_color: '#000000',
    accent_color: '#D35F00',
    primary_text_color: '#1A1A1A',
    accent_text_color: '#FFFFFF',
    background_color: '#FFFFFF'
    # logo: 'default_logo.png' # see ensure_logo below for logo attachment default
  )

  has_one_attached :logo
  after_initialize :merge_defaults, :ensure_logo

  def self.current_theme
    @current_theme ||= Theme.find_or_create_by(id: 1) do |theme|
      theme.merge_defaults
      theme.ensure_logo
      theme.save
    end
  end

  def reset_to_defaults
    self.attributes = attributes.merge(DEFAULTS)
    logo.purge
    ensure_logo
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
end
