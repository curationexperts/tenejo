# frozen_string_literal: true
class Import < Job
  delegate :manifest, to: :parent_job
end
