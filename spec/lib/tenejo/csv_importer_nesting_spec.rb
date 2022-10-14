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
    csv = fixture_file_upload("./spec/fixtures/csv/nesting_test_trimmed.csv")
    preflight = Preflight.create!(user: job_owner, manifest: csv)
    import_job = Import.create!(user: job_owner, graph: Tenejo::Preflight.process_csv(preflight.manifest.download, './spec/fixtures/images/structure_test'), parent_job: preflight)
    error_work = import_job.graph.root.children[1]
    error_work.title = nil
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
    import_graph = @csv_import.instance_variable_get(:@job).graph
    expect(import_graph.fatal_errors).to be_empty
    expect(import_graph.invalids).to be_empty
    expect(import_graph.warnings).to eq ["The column \'Comment\' is unknown and will be ignored"]
  end

  it 'sets error status', :aggregate_failures do
    import_job = @csv_import.instance_variable_get(:@job)
    error_work = import_job.graph.root.children[1]
    expect(error_work.identifier).to eq 'PROBLEM-WORK'
    expect(error_work.status).to eq 'errored'
  end

  it 'builds relationships', :aggregate_failures do
    parent = Collection.where(identifier_ssi: 'EPHEM').first
    child = Collection.where(identifier_ssi: 'CARDS').first
    grandchild = Work.where(identifier_ssi: 'CARDS-0001').first
    greatgrandchild = Work.where(identifier_ssi: 'CARDS-0001-J').first

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
    root_children = job.graph.root.children
    expect(root_children.map(&:identifier)).to eq ['ORPH-0001', 'PROBLEM-WORK', 'EPHEM']
    expect(root_children.map(&:status)).to eq ['completed', 'errored', 'completed']

    nested_work = job.graph.root.children[2].children[0].children[0].children[0].children[0]
    expect(nested_work.title).to eq ['Ace of Hearts']
    expect(nested_work.class).to eq Tenejo::PFWork
    expect(nested_work.status).to eq 'completed'

    attached_file = job.graph.root.children[2].children[0].children[0].children[1].children[1]
    expect(attached_file.class).to eq Tenejo::PFFile
    expect(attached_file.file).to eq '/jokers/Joker1-Verso.tiff'
    expect(attached_file.status).to eq 'completed'

    cards = job.graph.root.children[2].children[0].children[0].children
    expect(cards.map(&:title)).to eq [['Hearts'], ['Jokers']]
    expect(cards.map(&:status)).to eq ['completed', 'completed']
  end

  it 'sets file import status', :aggregate_failures do
    job = @csv_import.instance_variable_get(:@job)
    expect(job.graph.files[0].file).to eq "http://"
    expect(job.graph.files[0].status).to eq "errored"
    expect(job.graph.files[1].file).to eq "/jokers/Joker1-Recto.tiff"
    expect(job.graph.files[1].status).to eq "completed"
  end

  it 'sets work-level visibility', :aggregate_failures do
    private_work = Work.where(identifier_ssi: 'ORPH-0001').first
    institutional_work = Work.where(identifier_ssi: 'CARDS-0001-H-A').first
    public_work = Work.where(identifier_ssi: 'CARDS-0001-J').first

    expect(private_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    expect(institutional_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    expect(public_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  it 'sets collection-level visibility', :aggregate_failures do
    private_collection = Collection.where(identifier_ssi: 'DARK').first
    public_collection = Collection.where(identifier_ssi: 'CARDS').first

    expect(private_collection.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    expect(public_collection.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end
  # rubocop:enable RSpec/InstanceVariable
end
