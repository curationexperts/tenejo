# frozen_string_literal: true
require 'csv'
require 'rails_helper'
require 'active_fedora/cleaner'

RSpec.describe Tenejo::CsvImporter do
  before :all do
    # this nonsense is to create relevant files so that the preflighter will not reject the records
    r = CSV.read('spec/fixtures/csv/structure_test.csv')
    FileUtils.mkdir_p('tmp/test/uploads')
    r.map { |z| z[8] }.reject(&:nil?).map { |t| t.split('|~|') }.flatten.reject { |k| k == 'Files' }.each do |f|
      FileUtils.touch("tmp/test/uploads/#{f}")
    end
  end
  let(:job_owner) { FactoryBot.create(:user) }
  let(:csv) { fixture_file_upload("./spec/fixtures/csv/structure_test.csv") }
  let(:preflight) { Preflight.create!(user: job_owner, manifest: csv) }
  let(:import_job)  { Import.create!(user: job_owner, parent_job: preflight) }

  context "with fatal errors" do
    let(:csv) { fixture_file_upload("./spec/fixtures/csv/empty.csv") }
    # rubocop:disable RSpec/MessageSpies
    it "creates no objects" do
      csv_import = described_class.new(import_job)
      expect(csv_import).not_to receive(:instantiate)
      expect(csv_import).not_to receive(:make_files)
      csv_import.import
    end
  end

  it 'calls modules', :aggregate_failures do
    csv_import = described_class.new(import_job)
    allow(csv_import).to receive(:create_or_update_collection)
    allow(csv_import).to receive(:create_or_update_work)
    allow(csv_import).to receive(:create_or_update_file)

    csv_import.import

    expect(csv_import).to have_received(:create_or_update_collection).exactly(2).times
    expect(csv_import).to have_received(:create_or_update_work).exactly(12).times
    expect(csv_import).to have_received(:create_or_update_file).exactly(31).times
  end

  it 'creates parent-child relationships', :aggregate_failures do
    ActiveFedora::Cleaner.clean!
    csv_import = described_class.new(import_job)
    csv_import.import

    parent = Collection.where(identifier: 'EPHEM').last
    child = Collection.where(identifier: 'CARDS').last
    grandchild = Work.where(identifier: 'CARDS-0001').find { |w| w.identifier == ['CARDS-0001'] }
    greatgrandchild = Work.where(identifier: 'CARDS-0001-J').find { |w| w.identifier == ['CARDS-0001-J'] }

    expect(parent.child_collections).to include child
    expect(child.parent_collections).to include parent
    expect(child.child_collections).to be_empty
    expect(child.child_works).to include grandchild
    expect(greatgrandchild.parent_works).to include grandchild

    expect(Work.where(identifier: 'CARDS-0001').count).to be > 1, "remember to simplify these test when identifier is refactored"
  end

  context '.create_or_update_collection' do
    before { allow(Tenejo::Preflight).to receive(:process_csv) } # skip creating the preflight graph

    context "when collection doesn't exist" do
      # these tests are expensive, try to minimize how many we need to run
      before do
        # Ensure a collection with the expected :identifier does not exist
        # Collection.where(identifier: 'TEST0001').to_a.each { |c| c.destroy(eradicate: true) }
        ActiveFedora::Cleaner.clean!
        described_class.reset_default_collection_type!
      end
      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: 'TEST0001', title: 'Importer test collection' }, -1) }

      it "creates a new collection", :aggregate_failures do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_collection(pf_collection) }.to change { Collection.where(identifier: 'TEST0001').count }.from(0).to(1)
        collection = Collection.where(identifier: 'TEST0001').last
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
        collection =
          Collection.new(
            identifier: ['TEST0002'],
            title: ['Importer test collection'],
            date_uploaded: '2020-07-01 12:30:05',
            collection_type_gid: described_class.default_collection_type
          )
        collection.save!
      end

      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: 'TEST0002', title: 'Importer test collection' }, -1) }

      it "uses the existing collection instead of creating a new one" do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_collection(pf_collection) }.not_to change { Collection.where(identifier: 'TEST0002').count }
      end

      it "sets administrative data", :aggregate_failures do
        csv_import = described_class.new(import_job)
        csv_import.create_or_update_collection(pf_collection)
        collection = Collection.where(identifier: 'TEST0002').last
        expect(collection.depositor).not_to be_nil
        expect(collection.date_uploaded).to eq '2020-07-01 12:30:05' # should not be changed
        expect(collection.date_modified.in_time_zone).to be_within(1.minute).of Time.current
      end

      context 'with all the values' do
        let(:settable_attributes) {
          { "identifier" => "TEST0002", "title" => "Snappy title", "alternative_title" => "The other title",
            "resource_type" => "Image", "creator" => "c1", "contributor" => "c2", "description" => "a test fixture",
            "abstract" => "impressionism", "keyword" => "none", "license" => "http://creativecommons.org/publicdomain/mark/1.0/",
            "rights_notes" => "use freely", "rights_statement" => "http://rightsstatements.org/vocab/CNE/1.0/",
            "publisher" => "DCE", "date_created" => "2021-12-06", "subject" => "tbd", "language" => "english",
            "related_url" => "/also/#", "bibliographic_citation" => "yada yada", "source" => "mhb" }
        }
        let(:fixed_attributes) {
          { "id" => "fake0id", "depositor" => "fake_admin@example.org", "date_uploaded" => "2021-01-01 00:00:01",
          "date_modified" => nil, "head" => ['invalid value'], "tail" => ['invalid value'], "collection_type_gid" => "invalid_value", "has_model" => "european" }
        }
        let(:all_attributes) { settable_attributes.merge(fixed_attributes) }
        let(:pf_collection) { Tenejo::PFCollection.new(all_attributes, -1) }

        it "updates all of them", :aggregate_failures do
          csv_import = described_class.new(import_job)
          csv_import.create_or_update_collection(pf_collection)
          collection = Collection.where(identifier: 'TEST0002').last

          # Most settings should be updated by the import
          # TODO: the next two lines will break if/when any settable attributes are not multi-valued in the model
          wrapped_settable_attributes = settable_attributes.transform_values { |v| [v] }
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
    context "when work doesn't exist" do
      before do
        # Ensure a work with the expected :identifier does not exist
        ActiveFedora::Cleaner.clean!
      end
      let(:pf_work) { Tenejo::PFWork.new({ identifier: 'WORK-0001', title: 'Importer test work', rights_statement: "No Known Copyright" }, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

      it "creates a new work", :aggregate_failures do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_work(pf_work) }.to change { Work.where(identifier: 'WORK-0001').count }.from(0).to(1)
        work = Work.where(identifier: 'WORK-0001').last
        expect(work.depositor).to eq job_owner.user_key
        expect(work.date_uploaded.in_time_zone).to be_within(1.minute).of Time.current
        expect(work.title).to eq pf_work.title
        expect(work.rights_statement).to eq ["No Known Copyright"]
      end
    end

    context "with pre-existing work" do
      before(:context) do
        ActiveFedora::Cleaner.clean!
        # Ensure a  work with the expected :identifier exists -> 'WORK-0002'
        work =
          Work.new(
            identifier: ['WORK-0002'],
            title: ['Importer test WORK'],
            date_uploaded: '2020-07-01 12:30:05',
            rights_statement: ['In Copyright']
          )
        work.save!
      end

      let(:pf_work) { Tenejo::PFWork.new({ identifier: 'WORK-0002', title: 'Importer test work', rights_statement: 'In Copyright' }, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

      it "uses the existing work instead of creating a new one" do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_work(pf_work) }.not_to change { Work.where(identifier: 'WORK-0002').count }
      end

      it "sets administrative data", :aggregate_failures do
        csv_import = described_class.new(import_job)
        csv_import.create_or_update_work(pf_work)
        work = Work.where(identifier: 'WORK-0002').last
        expect(work.depositor).not_to be_nil
        expect(work.date_uploaded).to eq '2020-07-01 12:30:05' # should not be changed
        expect(work.date_modified.in_time_zone).to be_within(1.minute).of Time.current
      end

      context 'with all the values' do
        let(:settable_attributes) {
          { "identifier" => "WORK-0002", "title" => "Snappy title", "alternative_title" => "The other title",
            "resource_type" => "Image", "creator" => "c1", "contributor" => "c2", "description" => "a test fixture",
            "abstract" => "impressionism", "keyword" => "none", "license" => "All rights reserved",
            "rights_notes" => "use freely", "rights_statement" => "No Copyright - United States",
            "publisher" => "DCE", "date_created" => "2021-12-06", "subject" => "tbd", "language" => "english",
            "related_url" => "/also/#", "bibliographic_citation" => "yada yada", "source" => "mhb" }
        }
        let(:fixed_attributes) {
          { "id" => "fake0id", "depositor" => "fake_admin@example.org", "date_uploaded" => "2021-01-01 00:00:01",
            "date_modified" => nil, "head" => ['invalid value'], "tail" => ['invalid value'], "collection_type_gid" => "invalid_value", "has_model" => "european" }
        }
        let(:all_attributes) { settable_attributes.merge(fixed_attributes) }
        let(:pf_work) { Tenejo::PFWork.new(all_attributes, -1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }

        it "updates all of them", :aggregate_failures do
          csv_import = described_class.new(import_job)
          csv_import.create_or_update_work(pf_work)
          work = Work.where(identifier: 'WORK-0002').last

          # Most settings should be updated by the import
          # TODO: the next two lines will break if/when any settable attributes are not multi-valued in the model
          wrapped_settable_attributes = settable_attributes.transform_values { |v| [v] }
          expect(work.attributes).to include wrapped_settable_attributes

          # A handful of values should not have been modified even if they were in the preflight
          expect(work.id).not_to eq "fake0id"
          expect(work.depositor).not_to be_nil
          expect(work.depositor).not_to eq "fake_admin@example.org"
          expect(work.date_uploaded).to eq '2020-07-01 12:30:05' # should not change to 2021-01-01
          expect(work.date_modified.in_time_zone).to be_within(1.minute).of Time.current
        end
      end
    end
  end
end
