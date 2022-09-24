# frozen_string_literal: true
require 'rails_helper'
require 'tenejo/pf_object'

RSpec.describe Tenejo::Preflight do
  context '.process_csv' do
    let(:no_data) { described_class.process_csv(nil, nil) }
    it 'returns an error when input stream absent' do
      expect(no_data.fatal_errors).to include "No manifest present"
    end
  end

  context "a file with duplicate columns" do
    let(:dupes) { described_class.read_csv("spec/fixtures/csv/dupe_col.csv", "spec/fixtures/images/uploads") }

    it "records fatal error for duplicate column " do
      expect(dupes.fatal_errors).to include "Duplicate column names detected [:identifier, :identifier, :title, :title] cannot process"
    end
  end

  context "a file that isn't a csv " do
    let(:graph) { described_class.read_csv("spec/fixtures/images/tiny.jpg", "spec/fixtures/images/uploads") }
    it "returns a fatal error" do
      expect(graph.fatal_errors).to eq ["File format or encoding not recognized"]
    end
  end

  context "a file with no data" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/empty.csv", "spec/fixtures/images/uploads") }
    it "returns an empty graph" do
      expect(graph.root.children).to be_empty
    end

    it "records toplevel errors" do
      expect(graph.fatal_errors).to eq ["No data was detected"]
      expect(graph.warnings).to be_empty
    end
  end

  context "a file that has unmapped header names" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/unmapped.csv", "spec/fixtures/images/uploads") }
    it "records a warning for that row" do
      expect(graph.warnings).to include "The column 'frankabillity' is unknown and will be ignored"
    end
  end

  context "a row with too many columns" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/missing_cols.csv", "spec/fixtures/images/uploads") }
    it "records a warning for that row" do
      expect(graph.warnings).to eq ["The number of columns in row 2 differed from the number of headers (missing quotation mark?)"]
    end
  end

  context "a file with a bad object type" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/bad_ot.csv", "spec/fixtures/images/uploads") }

    it "records a warning for that row" do
      expect(graph.warnings).to eq ["Row 2: Unknown object type potato"]
    end
  end

  context "a file with header in it" do
    it "understands bad caps" do
      expect(described_class.map_header("KeY wOrD")).to eq :keyword
      expect(described_class.map_header("frank ability")).to eq "frank ability" # unmatched headers get returned as-is
      expect(described_class.map_header("RIGHTS_STATEMENT")).to eq :rights_statement
      expect(described_class.map_header("Rights Statement ")).to eq :rights_statement
    end
  end

  context "with missing required headers" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/noid.csv", "spec/fixtures/images/uploads") }
    it "requires required headers" do
      expect(graph.warnings.size).to eq 0
      expect(graph.fatal_errors).to include "Missing required column 'Identifier'"
      expect(graph.invalids.size).to eq(0)
    end
  end

  context "with invalid vocabulary entries" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/fancy.csv", "spec/fixtures/images/uploads") }

    it "gives a warning" do
      expect(graph.warnings.join).to include "Resource Type 'Photos' is not recognized"
    end
  end

  context "a well formed file" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/fancy.csv", "spec/fixtures/images/uploads") }

    it "checks for missing files in IMPORT_PATH" do
      expect(graph.files.first.valid?).to be true
    end

    it "records line number" do
      expect(graph.flatten.find { |x| x.is_a? Tenejo::PFWork }.lineno).to eq 10 # first "root" (no parent) work is on line 10
      expect(graph.flatten.find { |x| x.is_a? Tenejo::PFCollection }.lineno).to eq 2
      expect(graph.flatten.find { |x| x.is_a? Tenejo::PFFile }.lineno).to eq 5
    end

    it "connects files with parents" do
      expect(graph.root.children[1].children[0].children.map(&:file)).to eq ['MN-02 2.png', 'MN-02 3.png']
      expect(graph.root.children[1].children[1].children[0].file).to eq "MN-02 4.png"
    end

    it "connects works with works" do
      expect(graph.root.children[1].children[1].children.map(&:identifier)).to include "MPC008"
    end

    it "warns about disconnected works" do
      expect(graph.warnings).to include "Row 10: Could not find parent 'NONA'; work 'MPC009' will be created without a parent if you continue."
    end

    it "connects works and collections with parents" do
      expect(graph.collections.size).to eq 2
      expect(graph.collections.first.children.map(&:identifier)).to eq ["MPC002", "MPC003"]
      expect(graph.collections.last.children.map(&:identifier)).to be_empty
    end

    it "warns when work has no parent" do
      expect(graph.warnings).to include "Row 3: Could not find parent 'NONEXISTENT'; collection 'NONACOLLECTION' will be created without a parent if you continue."
    end

    it "warns files without parent in sheet" do
      expect(graph.warnings).to include "Row 6: Could not find parent work 'WHUT?' for file 'MN-02 2.png' - the file will be ignored"
    end

    it "parses out object types" do
      expect(graph.works.size).to eq 4
      expect(graph.collections.size).to eq 2
      expect(graph.files.size).to eq 3
    end

    it "has validation" do
      [:works, :collections].each do |x|
        graph.send(x).each do |y|
          expect(y.valid?).to eq true
        end
      end
      expect(graph.files.first.valid?).to be true
      expect(graph.files.last.valid?).to be true
    end

    it "includes warnings in the graph" do
      expect(graph.warnings.join).to include "Could not find parent 'NONEXISTENT'"
    end

    describe "graph structure" do
      it "has a root node" do
        expect(graph.root).to be_a Tenejo::PreFlightObj
      end

      it "root has at least 1 child for a valid CSV" do
        expect(graph.root.children.count).to be >= 1
      end

      it "connects collections without a parent in the CSV to the root" do
        expect(graph.root.children.map(&:identifier)).to include("TESTINGCOLLECTION")
      end

      it "connects works without a parent in the CSV to the root" do
        expect(graph.root.children.map(&:identifier)).to include("MPC009")
      end
    end
  end

  describe "assigns identifiers" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/file_id_test.csv", "spec/fixtures/images/uploads") }
    let(:hearts) { graph.root.children[0] }
    let(:diamonds) { graph.root.children[1] }
    let(:clubs) { graph.root.children[2] }
    let(:spades) { graph.root.children[3] }
    before do
      # Ignore file existence validations for these tests
      allow(Tenejo::PFFile).to receive(:exist?).and_return(true)
    end
    context "when explicit in the CSV" do
      example "for single files", :aggregate_failures do
        ace_of_spades = spades.children[0]
        expect(ace_of_spades.identifier).to eq 'CARDS-0001-S-A'
      end
      example "for files packed in a work", :aggregate_failures do
        king_of_clubs = clubs.children[3] # Arrays start at 0
        expect(king_of_clubs.identifier).to eq 'CARDS-0001-C.4' # identifier indexes start at 1
      end
    end
    context "automatically when absent" do
      example "for single files" do
        jack_of_diamonds = diamonds.children[2]
        expect(jack_of_diamonds.identifier).to eq "CARDS-0001-D//L10"
      end
      example "for packed files" do
        queen_of_diamonds_back = diamonds.children[4]
        expect(queen_of_diamonds_back.identifier).to eq "CARDS-0001-D//L11.2"
      end
      example "for files packed in files" do
        ace_of_hearts = hearts.children[1].children[0]
        expect(ace_of_hearts.identifier).to eq 'CARDS-0001-H-A.1'
      end
    end
  end

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
    let(:rec) { described_class.new(row, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }
    it "is not valid when blank" do
      expect(rec).not_to be_valid
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"], creator: ["can't be blank"]
      expect(rec.warnings).to include(visibility: ["Visibility is blank - and will be treated as private"])
    end

    context "with required fields" do
      let(:rec) { described_class.new(valid_row, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }
      it "validates successfully" do
        expect(rec).to be_valid
        expect(rec.errors).to be_empty
        expect(rec.warnings).to be_empty
      end
    end

    it "transforms visibility", :aggregate_failures do
      rec = described_class.new({ visibility: 'Public' }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      rec = described_class.new({ visibility: 'Authenticated' }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      rec = described_class.new({ visibility: 'PrIvAte' }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it "validates visibility" do
      rec = described_class.new({ visibility: 'spoon' }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(rec.valid?).not_to eq true # for other missing values, the import process will now treat any unrecognized values as private
      expect(rec.warnings[:visibility]).to eq ["Visibility is invalid: spoon - and will be treated as private"]
    end

    context ".license", :aggregate_failures do
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

    context ".rights_statement", :aggregate_failures do
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
      rec = described_class.new({ keyword: "Lions|~|Tigers|~|Bears" }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.keyword).to eq ["Lions", "Tigers", "Bears"]
    end

    it "wraps multi-value fields in an array", :aggregate_failures do
      rec = described_class.new({ title: "Have a nice day", visibility: "public" }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.title).to eq ["Have a nice day"]
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC # example of singular field not in an array
    end

    it "gives a warning if a single-valued field has packed data" do
      rec = described_class.new({ visibility: "public|~|private|~|jet" }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(rec.warnings[:visibility]).to eq ["Visibility has extra values: using 'public' -- ignoring: 'private, jet'"]
    end

    it "gives a warning if a controlled field has one or more invalid entries", :aggregate_failures do
      rec = described_class.new({ resource_type: "Poster|~|Airplane|~|Book|~|Bear" }, 1, Tenejo::DEFAULT_UPLOAD_PATH, 'placeholder for the graph')
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
    it "has a status", :aggregate_failures do
      expect(rec.status).to be nil
      rec.status = :submitted
      expect(rec.status.as_json).to eq 'submitted'
    end
  end
end
