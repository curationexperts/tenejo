# frozen_string_literal: true
require 'csv'
require 'rails_helper'
require 'active_fedora/cleaner'

RSpec.describe Tenejo::CsvImporter do
  let(:job_owner) { FactoryBot.create(:user) }
  let(:csv) { fixture_file_upload("./spec/fixtures/csv/nesting_test.csv") }
  let(:preflight) { Preflight.create!(user: job_owner, manifest: csv) }
  let(:import_job)  {
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(/png/).and_return(true)
    import = Import.create!(user: job_owner, parent_job: preflight, graph: Tenejo::Preflight.process_csv(preflight.manifest.download))
    import
  }

  context "with fatal errors", :aggregate_failures do
    let(:csv) { fixture_file_upload("./spec/fixtures/csv/empty.csv") }
    # rubocop:disable RSpec/MessageSpies
    it "creates no objects" do
      csv_import = described_class.new(import_job)
      expect(csv_import.preflight_errors).to eq ["No data was detected"]
      expect(csv_import).not_to receive(:create_or_update_collection)
      expect(csv_import).not_to receive(:create_or_update_work)
      csv_import.import

      expect(import_job.status).to eq 'errored'
      expect(import_job.completed_at).to be_within(1.second).of Time.current
    end
  end

  context "with non-fatal issues", :aggregate_failures do
    let(:csv) { fixture_file_upload("./spec/fixtures/csv/fancy.csv") }
    # rubocop:disable RSpec/MessageSpies
    it "returns warnings" do
      csv_import = described_class.new(import_job)
      expect(import_job.status).to eq 'submitted'
      expect(csv_import.preflight_errors).to eq []
      expect(csv_import.invalid_rows).to eq []
      expect(csv_import.preflight_warnings)
        .to contain_exactly(
              "The column \'Comment\' is unknown and will be ignored",
              "Row 3: Could not find parent \'NONEXISTENT\'; collection \'NONACOLLECTION\' will be created without a parent if you continue.",
              "Row 6: Could not find parent work \'WHUT?\' for file \'MN-02 2.png\' - the file will be ignored",
              "Row 10: Could not find parent \'NONA\'; work \'MPC009\' will be created without a parent if you continue.",
              "Row 2: Resource Type \'Photos\' is not recognized and will be omitted.",
              "Row 3: Resource Type \'Posters\' is not recognized and will be omitted.",
              "Row 5: Visibility is blank - and will be treated as private",
              "Row 5: Visibility is blank - and will be treated as private",
              "Row 6: Visibility is blank - and will be treated as private",
              "Row 8: Visibility is blank - and will be treated as private"
            )
    end
  end

  it 'calls modules', :aggregate_failures do
    csv_import = described_class.new(import_job)
    allow(csv_import).to receive(:create_or_update_collection)
    allow(csv_import).to receive(:create_or_update_work)

    csv_import.import

    expect(csv_import).to have_received(:create_or_update_collection).exactly(3).times
    expect(csv_import).to have_received(:create_or_update_work).exactly(9).times

    expect(import_job.status).to eq 'completed'
    expect(import_job.collections).to eq 3
    expect(import_job.works).to eq 9
    expect(import_job.files).to eq 2
    expect(import_job.completed_at).to be_within(1.second).of Time.current
  end

  context '.create_or_update_collection' do
    #    before { allow(Tenejo::Preflight).to receive(:process_csv) } # skip creating the preflight graph

    context "when collection doesn't exist" do
      # these tests are expensive, try to minimize how many we need to run
      before do
        # Ensure a collection with the expected :identifier does not exist
        # Collection.where(identifier_ssi: 'TEST0001').to_a.each { |c| c.destroy(eradicate: true) }
        ActiveFedora::Cleaner.clean!
        described_class.reset_default_collection_type!
      end
      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: 'TEST0001', title: 'Importer test collection' }, -1) }

      it "creates a new collection", :aggregate_failures do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_collection(pf_collection) }.to change { Collection.where(identifier_ssi: 'TEST0001').count }.from(0).to(1)
        collection = Collection.where(identifier_ssi: 'TEST0001').last
        expect(collection).not_to be_nil
        expect(collection.depositor).to eq job_owner.user_key
        expect(collection.date_uploaded.in_time_zone).to be_within(1.minute).of Time.current
        expect(collection.title).to eq pf_collection.title
        expect(collection.collection_type).to be_a_kind_of Hyrax::CollectionType
      end
    end

    context "with pre-existing collections" do
      before(:context) do
        ActiveFedora::Cleaner.clean!
        # Ensure a collection with the expected :identifier exists -> 'TEST0002'
        Collection.create!(
          identifier: 'TEST0002',
          title: ['Importer test collection'],
          date_uploaded: '2020-07-01 12:30:05',
          collection_type_gid: described_class.default_collection_type
        )
      end

      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: 'TEST0002', title: 'Importer test collection' }, -1) }

      it "uses the existing collection instead of creating a new one" do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_collection(pf_collection) }.not_to change { Collection.where(identifier_ssi: 'TEST0002').count }
      end

      it "sets administrative data", :aggregate_failures do
        csv_import = described_class.new(import_job)
        csv_import.create_or_update_collection(pf_collection)
        collection = Collection.where(identifier_ssi: 'TEST0002').last
        expect(collection.depositor).not_to be_nil
        expect(collection.date_uploaded).to eq '2020-07-01 12:30:05' # should not be changed
        expect(collection.date_modified.in_time_zone).to be_within(1.minute).of Time.current
      end

      context 'with all the values' do
        let(:settable_attributes) {
          { title: 'Snappy title', alternative_title: 'The other title|~|An other title',
            resource_type: 'Image', creator: 'c1', contributor: 'c2', description: 'a test fixture',
            abstract: 'impressionism', keyword: 'none', license: 'http://creativecommons.org/publicdomain/mark/1.0/',
            rights_notes: 'use freely', rights_statement: 'https://rightsstatements.org/vocab/CNE/1.0/',
            publisher: 'DCE', date_created: '2021-12-06', subject: 'tbd', language: 'english', related_url: '/also/#',
            bibliographic_citation: 'yada yada', source: 'mhb', other_identifiers: 'DOI|~|Handle|~|local' }
        }
        let(:fixed_attributes) {
          { identifier: 'TEST0002', depositor: 'fake_admin@example.org', date_uploaded: '2021-01-01 00:00:01',
            date_modified: nil, collection_type_gid: 'invalid_value', has_model: 'european' }
        }
        let(:all_attributes) { settable_attributes.merge(fixed_attributes) }
        let(:pf_collection) { Tenejo::PFCollection.new(all_attributes, -1) }

        it "updates all of them", :aggregate_failures do
          csv_import = described_class.new(import_job)
          csv_import.create_or_update_collection(pf_collection)
          collection = Collection.where(identifier_ssi: 'TEST0002').last

          # Most settings should be updated by the import
          # TODO: the next expectation will break if/when any settable attributes are not multi-valued in the model
          wrapped_settable_attributes = settable_attributes.transform_values { |v| v.split('|~|') }.transform_keys(&:to_s)
          expect(collection.attributes).to include wrapped_settable_attributes

          # A handful of values should not have been modified even if they were in the preflight
          expect(collection.id).not_to eq "fake0id"
          expect(collection.depositor).not_to be_nil
          expect(collection.depositor).not_to eq "fake_admin@example.org"
          expect(collection.date_uploaded).to eq '2020-07-01 12:30:05' # should not change to 2021-01-01
          expect(collection.date_modified.in_time_zone).to be_within(1.minute).of Time.current
        end
      end
    end
  end

  context '.create_or_update_work' do
    let(:admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

    context "when work doesn't exist" do
      before do
        # Ensure a work with the expected :identifier does not exist
        ActiveFedora::Cleaner.clean!
      end
      let(:pf_work) { Tenejo::PFWork.new({ identifier: 'WORK-0001', title: 'Importer test work', rights_statement: "No Known Copyright" }, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

      it "creates a new work", :aggregate_failures do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_work(pf_work) }.to change { Work.where(identifier_ssi: 'WORK-0001').count }.from(0).to(1)
        work = Work.where(identifier_ssi: 'WORK-0001').last
        expect(work.depositor).to eq job_owner.user_key
        expect(work.date_uploaded.in_time_zone).to be_within(1.minute).of Time.current
        expect(work.title).to eq pf_work.title
        expect(work.rights_statement).to eq ["https://rightsstatements.org/vocab/NKC/1.0/"]
        expect(Sipity::Entity(work).workflow_state.name).to eq 'deposited'
      end
    end

    context "with pre-existing work" do
      before(:context) do
        ActiveFedora::Cleaner.clean!
        # Ensure a work with the expected :identifier exists -> 'WORK-0002'
        Work.create!(
          identifier: 'WORK-0002',
          title: ['Importer test WORK'],
          date_uploaded: '2020-07-01 12:30:05',
          rights_statement: ['In Copyright']
        )
      end

      let(:pf_work) { Tenejo::PFWork.new({ identifier: 'WORK-0002', title: 'Importer test work', rights_statement: 'In Copyright' }, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

      it "uses the existing work instead of creating a new one" do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_work(pf_work) }.not_to change { Work.where(identifier_ssi: 'WORK-0002').count }
      end

      it "sets administrative data", :aggregate_failures do
        csv_import = described_class.new(import_job)
        csv_import.create_or_update_work(pf_work)
        work = Work.where(identifier_ssi: 'WORK-0002').last
        expect(work.depositor).not_to be_nil
        expect(work.date_uploaded).to eq '2020-07-01 12:30:05' # should not be changed
        expect(work.date_modified.in_time_zone).to be_within(1.minute).of Time.current
      end

      context 'with all the values' do
        let(:settable_attributes) {
          { title: 'Snappy title', alternative_title: 'Boring title|~|The other title',
            resource_type: 'Image', creator: 'c1', contributor: 'c2', description: 'a test fixture', abstract: 'impressionism',
            keyword: 'none', license: 'All rights reserved', rights_notes: 'use freely',
            rights_statement: 'https://rightsstatements.org/vocab/NoC-US/1.0/', publisher: 'DCE', date_created: '2021-12-06',
            subject: 'tbd', language: 'english', related_url: '/also/#', bibliographic_citation: 'yada yada', source: 'mhb',
            other_identifiers: 'DOI|~|Handle|~|local' }
        }
        let(:fixed_attributes) {
          { identifier: 'WORK-0002', depositor: 'fake_admin@example.org', date_uploaded: '2021-01-01 00:00:01', date_modified: nil,
            collection_type_gid: 'invalid_value', has_model: 'european' }
        }
        let(:all_attributes) { settable_attributes.merge(fixed_attributes) }
        let(:pf_work) { Tenejo::PFWork.new(all_attributes, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

        it "updates all of them", :aggregate_failures do
          csv_import = described_class.new(import_job)
          csv_import.create_or_update_work(pf_work)
          work = Work.where(identifier_ssi: 'WORK-0002').last

          # Most settings should be updated by the import
          # TODO: the next two lines will break if/when any settable attributes are not multi-valued in the model
          wrapped_settable_attributes = settable_attributes.transform_values { |v| v.split('|~|') }.transform_keys(&:to_s)
          expect(work.attributes).to include wrapped_settable_attributes
          expect(work.rights_statement).to eq ["https://rightsstatements.org/vocab/NoC-US/1.0/"]

          # A handful of values should not have been modified even if they were in the preflight
          expect(work.id).not_to eq "fake0id"
          expect(work.depositor).not_to be_nil
          expect(work.depositor).not_to eq "fake_admin@example.org"
          expect(work.date_uploaded).to eq '2020-07-01 12:30:05' # should not change to 2021-01-01
          expect(work.date_modified.in_time_zone).to be_within(1.minute).of Time.current
        end
      end

      context 'with thumbnails' do
        let(:csv) { fixture_file_upload("./spec/fixtures/csv/empty.csv") }
        it 'log an error when missing' do
          csv_import = described_class.new(import_job)
          node = Tenejo::PFWork.new({}, -1, nil, nil)
          node.identifier = ['ImNotHere']

          allow(Rails.logger).to receive(:error)
          csv_import.ensure_thumbnails(node)
          expect(Rails.logger).to have_received(:error).with(/ImNotHere/)
        end
      end
    end
  end

  context '.normalized_rights' do
    let(:csv_import) { described_class.new(import_job) }
    it 'works for vocabulary ids' do
      expect(csv_import.normalized_rights(['https://rightsstatements.org/vocab/InC/1.0/'])).to eq ['https://rightsstatements.org/vocab/InC/1.0/']
    end

    it 'works for vocabulary labels' do
      expect(csv_import.normalized_rights(['In Copyright'])).to eq ['https://rightsstatements.org/vocab/InC/1.0/']
    end

    it 'has a default for missing values' do
      expect(csv_import.normalized_rights(['invalid entry'])).to eq ['https://rightsstatements.org/vocab/CNE/1.0/']
    end
  end
end
