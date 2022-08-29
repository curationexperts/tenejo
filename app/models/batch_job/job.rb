# frozen_string_literal: true

class Job < ApplicationRecord
  belongs_to :user
  has_many :work_states, dependent: :nullify

  has_many :child_jobs, class_name: 'Job', foreign_key: 'parent_job_id', dependent: :nullify
  belongs_to :parent_job, class_name: 'Job', optional: true

  # Required to correctly reload Rails STI classes in development mode
  # see https://stackoverflow.com/questions/4125320/activerecord-model-subclasses-dont-show-up
  Dir.glob('app/models/batch_job/*.rb').each { |f| require_dependency File.basename(f, '.rb') } if Rails.env.development?
end
