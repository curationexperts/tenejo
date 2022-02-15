# frozen_string_literal: true
require 'csv'
require 'rails_helper'
require 'active_fedora/cleaner'
require 'hydra-file_characterization'

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
    csv = fixture_file_upload("./spec/fixtures/csv/file_test.csv")
    preflight = Preflight.create!(user: job_owner, manifest: csv)
    import_job = Import.create!(user: job_owner, parent_job: preflight)
    @csv_import = described_class.new(import_job, './spec/fixtures/images/structure_test')
    RSpec::Mocks.with_temporary_scope do
      # Suppress a legacy ActiveFedora warning: URI.escape is obsolete
      allow(URI).to receive(:encode) { |file_name| file_name }
      allow_any_instance_of(Hydra::FileCharacterization::Characterizer).to receive(:call) {
        File.read('spec/fixtures/images/structure_test/Joker1-Recto.fits.xml')
      }
      @csv_import.import
    end
  end

  after :all do
    conn = ActiveRecord::Base.connection
    conn.rollback_transaction if conn.transaction_open?
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @old_perform_enqueued_jobs
    ActiveJob::Base.queue_adapter = @old_queue_adapter
  end

  it 'attaches file_sets to works' do
    jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
    expect(jokers.file_sets.map(&:label)).to contain_exactly('Joker1-Recto.tiff', 'Joker2-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Verso.tiff')
  end

  it 'attaches packed & linked files in order' do
    jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
    expect(jokers.ordered_members.to_a.map(&:label)).to eq ['Joker1-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Recto.tiff', 'Joker2-Verso.tiff']
  end

  it 'attaches files to file_sets', :aggregate_failures do
    jokers = Work.where(primary_identifier_ssi: 'CARDS-0001-J').first
    joker = jokers.ordered_members.to_a.first
    expect(joker.original_file.mime_type).to eq "image/tiff"
    expect(joker.original_file.file_name).to eq ["Joker1-Recto.tiff"]
    expect(joker.original_file.width).to eq ["120"]
    expect(joker.original_file.height).to eq ["179"]
  end
  # rubocop:enable RSpec/InstanceVariable
end
