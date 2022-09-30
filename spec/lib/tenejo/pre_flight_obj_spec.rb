# frozen_string_literal: true
require 'rails_helper'
require 'tenejo/pf_object'

RSpec.describe Tenejo::PreFlightObj, :aggregate_failures do
  describe Tenejo::PFFile do
    let(:row) { {} }
    let(:rec) { described_class.new(row, 1, 'spec/fixtures/images/uploads') }
    it "is invalid when blank" do
      expect(rec.valid?).not_to eq true
    end

    it "gives an error if the file does not exist" do
      rec.file = 'missing.tiff'
      expect(rec.valid?).not_to eq true
      expect(rec.warnings[:file]).to be_empty
      expect(rec.errors[:file].join).to include 'missing.tiff'
    end

    it "restricts resource type" do
      rec.resource_type = ["Book", "foo"]
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type]).to eq ["Resource Type 'foo' is not recognized and will be omitted."]
    end

    context "#unpack" do
      it "does not raise an error if there are no files" do
        # Simulate a CSV that doesn't have a 'files' column
        row.delete(:files)
        expect { described_class.unpack(row, 1, '/import/path') }.not_to raise_error
      end

      it "warns when files are blank" do
        row = { object_type: 'File', identifier: 'TEST', parent: 'TEST-PARENT', title: 'Missing files column' }
        recs = described_class.unpack(row, 1, '/import/path')
        expect(recs.count).to eq 1
        expect(recs.first.valid?).to be false
        expect(recs.first.errors.messages[:file]).to include "can't be blank"
      end
    end

    context "path checking" do
      context "when strict" do
        it "returns the original file_name" do
          file_name = rec.relative_path('relative/path/to/file.ext', "./spec/fixtures/images", true)
          expect(file_name).to eq 'relative/path/to/file.ext'
        end
      end
      context "when not strict" do
        it "returns the relative path if the file exists" do
          file_name = rec.relative_path('Joker1-Recto.tiff', "./spec/fixtures/images", false)
          expect(file_name).to eq 'structure_test/jokers/Joker1-Recto.tiff'
        end
        it "ignores any relative paths" do
          file_name = rec.relative_path('ignore_this_path/Joker1-Recto.tiff', "./spec/fixtures/images", false)
          expect(file_name).to eq 'structure_test/jokers/Joker1-Recto.tiff'
        end
        it "returns a placeholder value when file does not exist" do
          file_name = rec.relative_path('relative/path/to/file.ext', "./spec/fixtures/images", false)
          expect(file_name).to eq '**/file.ext'
        end
      end
    end
  end

  describe Tenejo::PFWork do
    let(:row) { {} }
    let(:valid_row) { { identifier: 'ID', creator: 'Anon.', title: 'title', rights_statement: 'https://rightsstatements.org/vocab/UND/1.0/', visibility: 'public' } }
    let(:rec) { described_class.new(row, 1, '/import/path', Tenejo::Graph.new) }
    it "is not valid when blank" do
      expect(rec).not_to be_valid
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"], creator: ["can't be blank"]
      expect(rec.warnings).to include(visibility: ["Visibility is blank - and will be treated as private"])
    end

    context "with required fields" do
      let(:rec) { described_class.new(valid_row, 1, '/import/path', Tenejo::Graph.new) }
      it "validates successfully" do
        expect(rec).to be_valid
        expect(rec.errors).to be_empty
        expect(rec.warnings).to be_empty
      end
    end

    it "transforms visibility" do
      rec = described_class.new({ visibility: 'Public' }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      rec = described_class.new({ visibility: 'Authenticated' }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      rec = described_class.new({ visibility: 'PrIvAte' }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it "validates visibility" do
      rec = described_class.new({ visibility: 'spoon' }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(rec.valid?).not_to eq true # for other missing values, the import process will now treat any unrecognized values as private
      expect(rec.warnings[:visibility]).to eq ["Visibility is invalid: spoon - and will be treated as private"]
    end

    context ".license" do
      let(:row) { valid_row.merge({ license: license }) }

      context 'without a value' do
        let(:license) { '' } # in the CSV row
        it "is valid" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings).to be_empty
          expect(rec.license).to eq []
        end

        it 'handles scalars' do
          rec.license = '' # assigned after CSV parsing
          expect(rec).to be_valid
          expect(rec.warnings[:license]).to be_empty
          expect(rec.license).to eq []
        end

        it 'handles nil' do
          rec.license = nil
          expect(rec).to be_valid
          expect(rec.warnings[:license]).to be_empty
          expect(rec.license).to eq []
        end
      end

      context 'with vocabulary ids' do
        let(:license) { 'https://creativecommons.org/publicdomain/mark/1.0/' }
        it "validates successufully" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings).to be_empty
          expect(rec.license).to eq ['https://creativecommons.org/publicdomain/mark/1.0/']
        end
      end

      context 'with vocabulary labels' do
        let(:license) { 'Creative Commons BY Attribution 4.0 International' }
        it "validates successufully" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings).to be_empty
          expect(rec.license).to eq ['https://creativecommons.org/licenses/by/4.0/']
        end
      end

      context 'with invalid vocabulary entries' do
        let(:license) { 'not-a-valid-id-or-label' }
        it 'validates with warnings' do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:license]).to eq ["License '#{license}' is not recognized and will be omitted"]
          expect(rec.license).to be_empty
        end
      end

      context 'without exact matches' do
        let(:license) { 'Creative Commons' }
        it 'validates with warnings' do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:license]).to eq ["License '#{license}' is not recognized and will be omitted"]
          expect(rec.license).to be_empty
        end
      end

      context 'with multiple values' do
        let(:license) {
          ['Creative Commons BY Attribution 4.0 International',
           'not-a-valid-id-or-label',
           'https://creativecommons.org/publicdomain/mark/1.0/'].join('|~|')
        }
        it 'discards invalid vocabulary entries' do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:license]).to eq ["License 'not-a-valid-id-or-label' is not recognized and will be omitted"]
          expect(rec.license).to contain_exactly('https://creativecommons.org/licenses/by/4.0/',
                             'https://creativecommons.org/publicdomain/mark/1.0/')
        end
      end

      context 'with repeated values' do
        let(:license) {
          ['Creative Commons BY Attribution 4.0 International',
           'Creative Commons Public Domain Mark 1.0',
           'https://creativecommons.org/licenses/by/4.0/',
           'https://creativecommons.org/licenses/by/4.0/',
           'https://creativecommons.org/publicdomain/mark/1.0/'].join('|~|')
        }
        it 'de-duplicates entries' do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:license]).to be_empty
          expect(rec.license).to contain_exactly('https://creativecommons.org/licenses/by/4.0/',
                                                 'https://creativecommons.org/publicdomain/mark/1.0/')
        end
      end
    end

    context ".rights_statement" do
      let(:row) { valid_row.merge({ rights_statement: rights_statement }) }

      context 'validates sucessfully' do
        let(:rights_statement) { 'https://rightsstatements.org/vocab/InC/1.0/' }
        it "when entries are in the vocabulary" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings).to be_empty
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/InC/1.0/']
        end
      end

      context 'transforms human friendly labels' do
        let(:rights_statement) { 'No Known Copyright' }
        it 'to the corresponding URI' do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings).to be_empty
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/NKC/1.0/']
        end
      end

      context 'replaces blank entries' do
        let(:rights_statement) { '' }
        it "with undetermined" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:rights_statement]).to eq ["Rights Statement cannot be blank and will be set to 'Copyright Undetermined'"]
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/UND/1.0/']
        end
      end

      context 'with invalid entries' do
        let(:rights_statement) { 'not-a-valid-id-or-label' }
        it "get set to undetermined" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:rights_statement]).to eq ["Rights Statement 'not-a-valid-id-or-label' is not recognized and will be set to 'Copyright Undetermined'"]
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/UND/1.0/']
        end
      end

      context 'with inactive entries' do
        # active entries have https://, older inactive entries use http://
        let(:rights_statement) { 'http://rightsstatements.org/vocab/InC/1.0/' }
        it "get set to undetermined" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:rights_statement]).to eq ["Rights Statement 'http://rightsstatements.org/vocab/InC/1.0/' is not recognized and will be set to 'Copyright Undetermined'"]
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/UND/1.0/']
        end
      end

      context 'with inexact matches' do
        let(:rights_statement) { 'Copyright' }
        it "get set to undetermined" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:rights_statement]).to eq ["Rights Statement 'Copyright' is not recognized and will be set to 'Copyright Undetermined'"]
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/UND/1.0/']
        end
      end

      context 'with multiple entries' do
        let(:rights_statement) { 'https://rightsstatements.org/vocab/NKC/1.0/|~|not-a-valid-right' }
        it "only checks the first" do
          expect(rec).to be_valid
          expect(rec.errors).to be_empty
          expect(rec.warnings[:rights_statement]).to eq ["Rights Statement includes extra values which will be ignored"]
          expect(rec.rights_statement).to eq ['https://rightsstatements.org/vocab/NKC/1.0/']
        end
      end
    end

    it "restricts resource type" do
      rec.resource_type = ["foo"]
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type].join).to include "'foo' is not recognized and will be omitted."
    end

    it "can unpack" do
      p = Tenejo::PFFile.unpack({ files: "a|~|b|~|c", parent: 'p' }, 2, "spec/fixtures/images/uploads")
      expect(p).to be_an Array
      expect(p.size).to eq 3
      expect(p.first.file).to eq "a"
      expect(p.last.file).to eq "c"
    end

    it "unpacks multi-valued fields" do
      rec = described_class.new({ keyword: "Lions|~|Tigers|~|Bears" }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.keyword).to eq ["Lions", "Tigers", "Bears"]
    end

    it "wraps multi-value fields in an array" do
      rec = described_class.new({ title: "Have a nice day", visibility: "public" }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.title).to eq ["Have a nice day"]
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC # example of singular field not in an array
    end

    it "gives a warning if a single-valued field has packed data" do
      rec = described_class.new({ visibility: "public|~|private|~|jet" }, 1, '/import/path', Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(rec.warnings[:visibility]).to eq ["Visibility has extra values: using 'public' -- ignoring: 'private, jet'"]
    end

    it "gives a warning if a controlled field has one or more invalid entries" do
      rec = described_class.new({ resource_type: "Poster|~|Airplane|~|Book|~|Bear" }, 1, '/import/path', 'placeholder for the graph')
      expect(rec.valid?).to eq false
      expect(rec.resource_type).to eq ["Poster", "Book"]
      expect(rec.warnings[:resource_type].join).to include "'Airplane' is not recognized and will be omitted."
      expect(rec.warnings[:resource_type].join).to include "'Bear' is not recognized and will be omitted."
    end
  end

  describe Tenejo::PFCollection do
    let(:rec) { described_class.new({}, 1) }
    it "is not valid when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"]
      expect(rec.warnings[:visibility]).to eq ["Visibility is blank - and will be treated as private"]
    end

    it "restricts resource type" do
      rec.resource_type = ["foo"]
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type].join).to include "'foo' is not recognized and will be omitted."
    end
  end

  describe Tenejo::PreFlightObj do
    let(:rec) { described_class.new({}, 1) }
    it "has a status" do
      expect(rec.status).to be nil
      rec.status = :submitted
      expect(rec.status.as_json).to eq 'submitted'
    end
  end
end
