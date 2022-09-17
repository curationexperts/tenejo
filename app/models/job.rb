# frozen_string_literal: true

class Job < ApplicationRecord
  belongs_to :user
  has_many :work_states, dependent: :nullify

  has_many :child_jobs, class_name: 'Job', foreign_key: 'parent_job_id', dependent: :nullify
  belongs_to :parent_job, class_name: 'Job', optional: true

  def graph
    @memo ||= Tenejo::Graph.from(attribute(:graph))
  end

  def collections
    graph.collections.count
  end

  def works
    graph.works.count
  end

  def files
    graph.files.count
  end
end
