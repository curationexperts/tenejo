# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tenejo::CsvImporter do
  let(:job_owner) { FactoryBot.create(:user) }
  let(:csv) { fixture_file_upload("./spec/fixtures/csv/fancy.csv") }
  let(:preflight) { Preflight.create!(user: job_owner, manifest: csv) }
  let(:import_job)  { Import.create!(user: job_owner, parent_job: preflight) }

  context "with fatal errors" do
    let(:csv) { fixture_file_upload("./spec/fixtures/csv/empty.csv") }
    # rubocop:disable RSpec/MessageSpies
    it "creates no objects" do
      csv_import = described_class.new(import_job)
      expect(csv_import).not_to receive(:make_collections)
      expect(csv_import).not_to receive(:make_works)
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
    expect(csv_import).to have_received(:create_or_update_work).exactly(4).times
    expect(csv_import).to have_received(:create_or_update_file).exactly(4).times
  end

  context '.create_or_update_collection' do
    before { allow(Tenejo::Preflight).to receive(:process_csv) } # skip creating the preflight graph

    context "collection with identifier not found" do
      # these tests are expensive, try to minimize how many we need to run
      before do
        # Ensure a collection with the expected :identifier does not exist
        Collection.where(identifier: 'TEST0001').to_a.each { |c| c.destroy(eradicate: true) }
      end
      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: ['TEST0001'], title: ['Importer test collection'] }, -1) }

      it "creates a new collection", :aggregate_failures do
        csv_import = described_class.new(import_job)
        expect { csv_import.create_or_update_collection(pf_collection) }.to change { Collection.where(identifier: 'TEST0001').count }.from(0).to(1)
        collection = Collection.where(identifier: 'TEST0001').last
        expect(collection.depositor).to eq job_owner.user_key
        expect(collection.date_uploaded.in_time_zone).to be_within(1.minute).of Time.current
        expect(collection.title).to eq pf_collection.title
      end
    end

    context "with pre-existing collections" do
      before(:context) do
        # Ensure a collection with the expected :identifier exists -> 'TEST0002'
        collection =
          Collection.new(
            identifier: ['TEST0002'],
            title: ['Importer test collection'],
            date_uploaded: '2020-07-01 12:30:05',
            collection_type_gid: described_class.default_collection_type
          )
        begin
          collection.save!
        rescue Ldp::Conflict
          collection.save! # I know this seems ridiculous, but tests were flaky otherwise...
        end
      end
      let(:pf_collection) { Tenejo::PFCollection.new({ identifier: ['TEST0002'], title: ['Importer test collection'] }, -1) }

      after(:context) do
        Collection.where(identifier: 'TEST0002').to_a.each { |c| c.destroy(eradicate: true) }
      end

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
          { "identifier" => ["TEST0002"], "title" => ["Snappy title"], "alternative_title" => ["The other title"],
          "label" => "Not a real title", "relative_path" => "path/to/file.ext", "import_url" => "https:://localhost:3000/import",
          "resource_type" => ["Image"], "creator" => ["c1"], "contributor" => ["c2"], "description" => ["a test fixture"],
          "abstract" => ["used for tests"], "keyword" => ["none"], "license" => ["http://creativecommons.org/publicdomain/mark/1.0/"],
          "rights_notes" => ["use freely"], "rights_statement" => ["http://rightsstatements.org/vocab/CNE/1.0/"],
          "access_right" => ["free to use"], "publisher" => ["DCE"], "date_created" => ["2021-12-06"], "subject" => ["tbd"],
          "language" => ["english"], "based_near" => [], "related_url" => ["/also/#"], "bibliographic_citation" => ["yada yada"], "source" => ["mhb"] }
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
          expect(collection.attributes).to include settable_attributes

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
end
