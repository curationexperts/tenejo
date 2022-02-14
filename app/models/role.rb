# frozen_string_literal: true

# Class modeling Roles within the application
class Role < ApplicationRecord
  has_and_belongs_to_many :users

  validates :name,
            uniqueness: true
end
