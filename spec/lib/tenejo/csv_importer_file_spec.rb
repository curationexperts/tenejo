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
    ace_of_hearts = Work.new(title: ['Ace of Hearts'], identifier: 'CARDS-AH', description: ['A pre-existing work'], rights_statement: ["http://rightsstatements.org/vocab/NoC-OKLR/1.0/"])
    ace_of_hearts.ordered_members << FileSet.create!
    ace_of_hearts.save!

    job_owner = User.find_by(email: 'admin@example.org') || User.create(email: 'admin@example.org', password: 'abcd5678')
    csv = fixture_file_upload("./spec/fixtures/csv/file_test.csv")
    preflight = Preflight.create!(user: job_owner, manifest: csv)
    import_job = Import.create!(user: job_owner, parent_job: preflight, graph: Tenejo::Preflight.process_csv(preflight.manifest.download, './spec/fixtures/images/structure_test'))
    @csv_import = described_class.new(import_job)
    RSpec::Mocks.with_temporary_scope do
      # Suppress a legacy ActiveFedora warning: URI.escape is obsolete
      allow(URI).to receive(:encode) { |file_name| file_name }
      # Suppress a legacy LDP warning: URI.unescape is obsolete
      allow(URI).to receive(:decode) { |file_name| file_name }
      # Bypass calling FITS in CI environments
      allow_any_instance_of(Hydra::FileCharacterization::Characterizer).to receive(:call) {
        File.read('spec/fixtures/images/structure_test/jokers/Joker1-Recto.fits.xml')
      }
      @csv_import.import

      # make all the tests fail if we've somehow broken the test setup
      expect(@csv_import.preflight_errors).to be_empty
      expect(@csv_import.preflight_warnings).to be_empty
    end
  end

  after :all do
    conn = ActiveRecord::Base.connection
    conn.rollback_transaction if conn.transaction_open?
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @old_perform_enqueued_jobs
    ActiveJob::Base.queue_adapter = @old_queue_adapter
  end
  # rubocop:enable RSpec/InstanceVariable

  let(:jokers) { Work.where(identifier_ssi: 'CARDS-0001-J').first }
  let(:joker_1_front) { jokers.ordered_members.to_a.first }

  it 'only creates one work with the expected id' do
    hits = Work.where(identifier_ssi: 'CARDS-0001-J').count
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
    nested_jokers = Work.where(identifier_ssi: 'CARDS-0001-J').first
    expect(nested_jokers.thumbnail).to eq joker_1_front
  end

  it 'sets representative media' do
    expect(jokers.representative).to eq joker_1_front
  end

  it 'adds files to existing works', :aggregate_failures do
    ace_of_hearts = Work.where(identifier_ssi: 'CARDS-AH').last
    expect(ace_of_hearts.title).to eq ['Ace of Hearts']
    expect(ace_of_hearts.description).to eq ['No Jokers here'] # changed from 'A pre-existing work'
    expect(ace_of_hearts.ordered_members.to_a.size).to eq 2 # started with 1 and added 1 during import
    expect(ace_of_hearts.modified_date).not_to eq ace_of_hearts.create_date # modified_date should have been modified by the importer
  end
end
