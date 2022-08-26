# frozen_string_literal: true
class Export < Job
  has_one_attached :manifest
end
