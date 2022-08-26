# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Import, type: :model do
  context ".manifest" do
    it 'delegates to the parent_job' do
      job = described_class.new(parent_job: Preflight.new)
      expect(job.manifest.class).to eq ActiveStorage::Attached::One
      expect(job.manifest).not_to be_attached
    end

    it "raises an error when no parent is set" do
      job = described_class.new
      expect { job.manifest }.to raise_error(NoMethodError)
    end

    it "raises an error when the parent class doesn't implement .manifest" do
      job = described_class.new(parent_job: Job.new)
      expect { job.manifest }.to raise_error(NoMethodError)
    end
  end
end
