# frozen_string_literal: true

# Class modeling Roles within the application
class Role < ApplicationRecord
  before_destroy :pre_destroy_check_admin
  has_and_belongs_to_many :users # # rubocop:disable Rails/HasAndBelongsToMany
  validates :name, uniqueness: true

  private

  def pre_destroy_check_admin
    return if name == "admin"
    errors.add(:base, "is indestructible")
    throw :abort
  end
end
