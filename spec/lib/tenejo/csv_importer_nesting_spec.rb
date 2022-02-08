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
    csv = fixture_file_upload("./spec/fixtures/csv/structure_test.csv")
    preflight = Preflight.create!(user: job_owner, manifest: csv)
    import_job = Import.create!(user: job_owner, parent_job: preflight)
    @csv_import = described_class.new(import_job, './spec/fixtures/images/structure_test')
    RSpec::Mocks.with_temporary_scope do
      allow(CharacterizeJob).to receive(:perform_later)
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

  context 'file behaviors' do
    it 'attaches file_sets to works' do
      jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
      expect(jokers.file_sets.map(&:label)).to contain_exactly('Joker1-Recto.tiff', 'Joker2-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Verso.tiff')
    end

    it 'attaches files to file_sets', :aggregate_failures do
      jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
      joker = jokers.ordered_members.to_a.first
      expect(joker.original_file.mime_type).to eq "image/tiff"
      expect(joker.original_file.file_name).to eq ["Joker1-Recto.tiff"]
    end

    it 'attaches packed files in order' do
      jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
      expect(jokers.ordered_members.to_a.map(&:label)).to eq ['Joker1-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Recto.tiff', 'Joker2-Verso.tiff']
    end

    it 'attaches linked files in order' do
      spades = Work.where(primary_identifier_ssi: 'CARDS-0001-S').first
      expect(spades.ordered_members.to_a.map(&:label)).to eq ["As-Piques-Recto.tiff", "Valet-Piques-Recto.tiff", "Dame-Piques-Recto.tiff", "Roi-Piques-Recto.tiff"]
    end
  end
  # rubocop:enable RSpec/InstanceVariable
end
