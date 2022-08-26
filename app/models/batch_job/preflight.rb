# frozen_string_literal: true
class Preflight < Job
  has_one_attached :manifest
  validate :manifest_attached

  private

  def manifest_attached
    return if manifest.attached?
    errors.add(:manifest, "must be attached")
  end
end
