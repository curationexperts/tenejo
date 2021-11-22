# frozen_string_literal: true
json.extract! job, :id, :type, :label, :user_id, :status, :completed_at, :collections, :works, :files, :created_at, :updated_at
json.url job_url(job, format: :json)
