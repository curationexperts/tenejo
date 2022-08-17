# frozen_string_literal: true
class WorkState < ApplicationRecord
  belongs_to :job

  def self.from_job(graph, job)
    job_id = job.id

    WorkState.transaction do
      @graph.collections.each do |coll|
        ws = WorkState.new state: 'created', job_id: job_id, row_identifier: coll.row
      end
    end
  end
end
