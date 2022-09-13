# frozen_string_literal: true
require 'csv'
require 'rails_helper'
require 'active_fedora/cleaner'

RSpec.describe Tenejo::CsvImporter do
  # rubocop:disable RSpec/InstanceVariable
  before :all do
    ActiveRecord::Base.connection.begin_transaction
    ActiveFedora::Cleaner.clean!
    described_class.reset_default_collection_type!
    @old_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    @old_perform_enqueued_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

    job_owner = User.find_by(email: 'admin@example.org') || User.create(email: 'admin@example.org', password: 'abcd5678')
    csv = fixture_file_upload("./spec/fixtures/csv/nesting_test.csv")
    preflight = Preflight.create!(user: job_owner, manifest: csv)
    import_job = Import.create!(user: job_owner, graph: Tenejo::Preflight.process_csv(preflight.manifest.download, './spec/fixtures/images/structure_test'), parent_job: preflight)
    @csv_import = described_class.new(import_job)
    RSpec::Mocks.with_temporary_scope do
      # Stub file creation - test this separately in an import with fewer elements
      # This cuts the test time from over 3.5 minutes down to around 30 seconds.
      allow(IngestLocalFileJob).to receive(:perform_now)
      @csv_import.import
    end
  end

  after :all do
    conn = ActiveRecord::Base.connection
    conn.rollback_transaction if conn.transaction_open?
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @old_perform_enqueued_jobs
    ActiveJob::Base.queue_adapter = @old_queue_adapter
  end

  it 'runs without errors', :aggregate_failures do
    expect(@csv_import.preflight_errors).to be_empty
    expect(@csv_import.invalid_rows).to be_empty
    expect(@csv_import.preflight_warnings).to eq ["The column \"Comment\" is unknown, and will be ignored"]
  end

  it 'builds relationships', :aggregate_failures do
    parent = Collection.where(primary_identifier_ssi: 'EPHEM').first
    child = Collection.where(primary_identifier_ssi: 'CARDS').first
    grandchild = Work.where(primary_identifier_ssi: 'CARDS-0001').first
    greatgrandchild = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first

    expect(parent.child_collections).to include child
    expect(child.parent_collections).to include parent
    expect(child.child_collections).to be_empty
    expect(child.child_works).to include grandchild
    expect(greatgrandchild.parent_works).to include grandchild
  end

  it 'sets item-level import status', :aggregate_failures do
    # TODO: figure out a more readable test
    # There should probably be some clearer unit-level tests too.

    job = @csv_import.instance_variable_get(:@job)
    root_children = job.graph['root']['children']
    root_children_status = root_children.map { |c| c['status'] }
    expect(root_children_status).to eq ["complete", "complete", "complete"]

    first_child = job.graph['root']['children'][2]['children'][0]['children'][0]['children'][0]['children'][0]
    expect(first_child['title']).to eq ["Ace of Hearts"]
    expect(first_child['status']).to eq "complete"

    hearts_status = job.graph['root']['children'][2]['children'][0]['children'][0]['children'].map { |c| c['status'] }
    expect(hearts_status).to eq ["complete", "complete", "complete", "complete", "complete"]
  end
  it 'sets file import status', :aggregate_failures do
    job = @csv_import.instance_variable_get(:@job)
    expect(job.graph['root'].dig('children', 1, 'files', 0, 'status')).to eq "complete"
  end

  it 'sets work-level visibility', :aggregate_failures do
    private_work = Work.where(primary_identifier_ssi: 'ORPH-0001').first
    institutional_work = Work.where(primary_identifier_ssi: 'ORPH-0002').first
    public_work = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first

    expect(private_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    expect(institutional_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    expect(public_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  it 'sets collection-level visibility', :aggregate_failures do
    private_collection = Collection.where(primary_identifier_ssi: 'DARK').first
    public_collection = Collection.where(primary_identifier_ssi: 'CARDS').first

    expect(private_collection.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    expect(public_collection.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end
  # rubocop:enable RSpec/InstanceVariable
end
