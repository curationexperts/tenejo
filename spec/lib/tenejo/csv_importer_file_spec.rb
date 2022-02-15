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
      # Suppress a legacy LDP warning: URI.unescape is obsolete
      allow(URI).to receive(:decode) { |file_name| file_name }
      # Bypass calling FITS in CI environments
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
  # rubocop:enable RSpec/InstanceVariable

  let(:jokers) { Work.where(primary_identifier_ssi: 'CARDS-0001-J').first }
  let(:joker_1_front) { jokers.ordered_members.to_a.first }

  it 'only creates one work with the expected id' do
    hits = Work.where(primary_identifier_ssi: 'CARDS-0001-J').count
    expect(hits).to eq 1
  end

  it 'attaches file_sets to works' do
    expect(jokers.file_sets.map(&:label)).to contain_exactly('Joker1-Recto.tiff', 'Joker2-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Verso.tiff')
  end

  it 'attaches packed & linked files in order' do
    expect(jokers.ordered_members.to_a.map(&:label)).to eq ['Joker1-Recto.tiff', 'Joker1-Verso.tiff', 'Joker2-Recto.tiff', 'Joker2-Verso.tiff']
  end

  it 'attaches files to file_sets', :aggregate_failures do
    expect(joker_1_front.original_file.mime_type).to eq "image/tiff"
    expect(joker_1_front.original_file.file_name).to eq ["Joker1-Recto.tiff"]
    expect(joker_1_front.original_file.width).to eq ["120"]
    expect(joker_1_front.original_file.height).to eq ["179"]
  end

  it 'sets thumbnails from attached files' do
    expect(jokers.thumbnail).to eq joker_1_front
  end

  it 'sets thumbnails from attached works' do
    nested_jokers = Work.where(primary_identifier_ssi: 'CARDS-JJ').first
    expect(nested_jokers.thumbnail).to eq joker_1_front
  end

  it 'sets representative media' do
    expect(jokers.representative).to eq joker_1_front
  end
end
