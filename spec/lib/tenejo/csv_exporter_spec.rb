# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tenejo::CsvExporter do
  let(:job_owner) { FactoryBot.create(:user) }
  let(:export) { Export.create(user: job_owner) }

  after do
    # active storage files are not deleted automatically
    export.manifest.purge
  end

  context 'CSV' do
    let(:col001) {
      Collection.new(title: ['Test collection'], primary_identifier: 'COL001',
                     collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.gid)
    }

    let(:work001) { Work.new(title: ['Test work'], primary_identifier: 'WRK001') }

    it 'gets attached on export', :aggregate_failures do
      expect(export.manifest.attached?).to be false
      described_class.new(export).run
      expect(export.manifest.attached?).to be true
    end

    it 'includes error message if no identifiers were provided' do
      described_class.new(export).run
      rows = CSV.parse(export.manifest.download, headers: true)
      expect(rows.first['error']).to eq 'No identifiers provided'
    end

    it 'includes row-level errors' do
      export.identifiers = ['invalid_id']
      export.save
      described_class.new(export).run
      rows = CSV.parse(export.manifest.download, headers: true)
      expect(rows.first['primary_identifier']).to eq 'invalid_id'
      expect(rows.first['error']).to eq 'No match for identifier'
    end

    it 'includes metadata for collections and works', :aggregate_failures do
      allow(ActiveFedora::Base).to receive(:where).and_return([col001], [work001])

      export.identifiers = ['COL001', 'WRK001']
      export.save
      described_class.new(export).run
      rows = CSV.parse(export.manifest.download, headers: true)

      # Collection COL001
      expect(rows[0]['primary_identifier']).to eq 'COL001'
      expect(rows[0]['error']).to be_nil
      expect(rows[0]['title']).to include 'Test collection'
      expect(rows[0]['class']).to eq "Collection"

      # Work WRK001
      expect(rows[1]['primary_identifier']).to eq 'WRK001'
      expect(rows[1]['error']).to be_nil
      expect(rows[1]['title']).to include 'Test work'
      expect(rows[1]['class']).to eq "Work"
    end
  end

  context "#serialize" do
    let(:max_work) {
      Work.new(
        title: ['Work with all the fields'],
        primary_identifier: 'MAX-WORK',
        identifier: ['DOI:xxxxxxx', 'http://hdl.handle.net/ooooo/iiiiiiiii'],
        alternative_title: ['Alle Felder', 'सर्वाणि क्षेत्राणि'],
        resource_type: ["Image"],
        creator: ["Anon., 16th Century"],
        contributor: ["c2"],
        description: ["Here's some mixed \"s & quotes'"],
        abstract: ["impressionism"],
        keyword: ["none", "one", "some"],
        license: ["All rights reserved"],
        rights_notes: ["use freely"],
        rights_statement: ["No Copyright - United States"],
        publisher: ["DCE"],
        date_created: ["2021-12-06"],
        subject: ["tbd"],
        language: ["english"],
        related_url: ["/also/#"],
        bibliographic_citation: ["see also"],
        source: ["mhb"],
        # single valued
        depositor: "admin@example.com",
        date_uploaded: "2021-01-01 00:00:01",
        date_modified: nil
      )
    }

    let(:serialized) { described_class.new(user: job_owner).send(:serialize, 'MAX-WORK') }

    before do
      allow(ActiveFedora::Base).to receive(:where).and_return([max_work])
    end

    it "returns a string" do
      expect(serialized).to be_a CSV::Row
    end

    it "handles all the fields" do
      # Just check for one value deep in the array
      # Otherwise we need to check the whole exact string and the test becomes fragile
      expect(serialized[:rights_notes]).to include 'use freely'
    end

    it "handles multi-valued fields" do
      expect(serialized[:alternative_title].split('|~|')).to contain_exactly('Alle Felder', 'सर्वाणि क्षेत्राणि')
    end

    it "handles embedded quotes" do
      expect(serialized[:description]).to eq %q(Here's some mixed "s & quotes')
    end

    it "handles embedded commas" do
      expect(serialized[:creator]).to eq 'Anon., 16th Century'
    end
  end
end
