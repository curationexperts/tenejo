# frozen_string_literal: true
class Theme < ApplicationRecord
  DEFAULTS = ActiveSupport::HashWithIndifferentAccess.new(
    site_title: 'Tenejo',
    primary_color: '#000000',
    accent_color: '#D35F00',
    primary_text_color: '#1A1A1A',
    accent_text_color: '#FFFFFF',
    background_color: '#FFFFFF'
  )

  after_initialize :merge_defaults

  def merge_defaults
    self.attributes = attributes.compact.reverse_merge(DEFAULTS)
  end

  def self.current_theme
    @current_theme ||= Theme.find_or_create_by(id: 1) do |theme|
      theme.merge_defaults
    end
  end

  def reset_to_defaults
    self.attributes = attributes.merge(DEFAULTS)
  end
end
