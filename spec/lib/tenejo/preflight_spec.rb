# frozen_string_literal: true
require 'rails_helper'
require 'tenejo/pf_object'
require 'fileutils'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Tenejo::Preflight do
  before :all do
    FileUtils.mkdir_p("tmp/uploads")
    FileUtils.touch("tmp/uploads/MN-02 2.png")
    FileUtils.touch("tmp/uploads/MN-02 3.png")
    FileUtils.touch("tmp/uploads/MN-02 4.png")
  end
  after :all do
    FileUtils.rm_r("tmp/uploads")
  end

  context '.process_csv' do
    let(:no_data) { described_class.process_csv(nil, nil) }
    it 'returns an error when input stream absent' do
      expect(no_data.fatal_errors).to include "No manifest present"
    end
  end

  context "a file with duplicate columns" do
    let(:dupes) { described_class.read_csv("spec/fixtures/csv/dupe_col.csv", "tmp/uploads") }

    it "records fatal error for duplicate column " do
      expect(dupes.fatal_errors).to include "Duplicate column names detected [:identifier, :identifier, :title, :title], cannot process"
    end
  end
  context "a file that isn't a csv " do
    let(:graph) { described_class.read_csv("spec/fixtures/images/tiny.jpg", "tmp/uploads") }
    it "returns a fatal error" do
      expect(graph.fatal_errors).to eq ["File format or encoding not recognized"]
    end
  end
  context "a file with no data" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/empty.csv", "tmp/uploads") }
    it "returns an empty graph" do
      [:works, :collections, :files].each do |x|
        expect(graph.send(x)).to be_empty
      end
    end
    it "records toplevel errors" do
      expect(graph.fatal_errors).to eq ["No data was detected"]
      expect(graph.warnings).to be_empty
    end
  end

  context "a file that has unmapped header names" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/unmapped.csv", "tmp/uploads") }
    it "records a warning for that row" do
      expect(graph.warnings).to include "The column \"frankabillity\" is unknown, and will be ignored"
    end
  end

  context "a row with too many columns" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/missing_cols.csv", "tmp/uploads") }
    it "records a warning for that row" do
      expect(graph.warnings).to eq ["The number of columns in row 2 differed from the number of headers (missing quotation mark?)"]
    end
  end

  context "a file with a bad object type" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/bad_ot.csv", "tmp/uploads") }

    it "records a warning for that row" do
      expect(graph.warnings).to eq ["Uknown object type on row 2: potato"]
    end
  end

  context " a file with header in it" do
    it "understands bad caps" do
      expect(described_class.map_header("KeY wOrD")).to eq :keyword
      expect(described_class.map_header("frank ability")).to eq "frank ability"
      expect(described_class.map_header("RIGHTS_STATEMENT")).to eq :rights_statement
      expect(described_class.map_header("Rights Statement ")).to eq :rights_statement
    end
  end
  context "with missing required headers" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/noid.csv", "tmp/uploads") }
    it "requires required headers" do
      expect(graph.warnings.size).to eq 0
      expect(graph.fatal_errors).to include "Missing required column 'Identifier'"
      expect(graph.invalids.size).to eq(0)
    end
  end

  context "with invalid vocabulary entries" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/fancy.csv", "tmp/uploads") }

    it "gives a warning" do
      expect(graph.warnings.join).to include 'Resource Type "Photos" is not recognized'
    end
  end

  context "a well formed file" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/fancy.csv", "tmp/uploads") }

    it "checks for missing files in IMPORT_PATH" do
      expect(graph.files.first.valid?).to be true
    end

    it "records line number" do
      expect(graph.works.first.lineno).to eq 4
      expect(graph.collections.first.lineno).to eq 2
      expect(graph.files.first.lineno).to eq 5
    end

    it "connects files with parents" do
      expect(graph.works.first.files.map(&:file)).to eq ['MN-02 2.png', 'MN-02 3.png']
      expect(graph.works[1].files.map(&:file)).to eq ["MN-02 4.png"]
    end
    it "connects works with works" do
      expect(graph.works[1].children.map(&:identifier)).to eq [["MPC008"]]
    end
    it "warns about disconnected  works" do
      expect(graph.warnings).to include "Could not find parent \"NONA\" on line 10; work \"MPC009\" will be created without a parent if you continue."
    end
    it "connects works and collections with parents" do
      expect(graph.collections.size).to eq 2
      expect(graph.collections.first.children.map(&:identifier)).to eq [["MPC002"], ["MPC003"]]
      expect(graph.collections.last.children.map(&:identifier)).to be_empty
    end
    it "warns when work has no parent" do
      expect(graph.warnings).to include "Could not find parent \"NONEXISTENT\" on line 3; collection \"NONACOLLECTION\" will be created without a parent if you continue."
    end
    it "warns files without parent in sheet" do
      expect(graph.warnings).to include "Could not find parent work \"WHUT?\" for file \"MN-02 2.png\" on line 6 - the file will be ignored"
    end

    it "parses out object types" do
      expect(graph.works.size).to eq 4
      expect(graph.collections.size).to eq 2
      expect(graph.files.size).to eq 4
    end

    it "has validation" do
      FileUtils.touch("tmp/uploads/MN-02 4.png")
      [:works, :collections].each do |x|
        graph.send(x).each do |y|
          expect(y.valid?).to eq true
        end
      end
      expect(graph.files.first.valid?).to be true
      expect(graph.files.last.valid?).to be true
    end

    it "includes warnings in the graph" do
      expect(graph.warnings.join).to include "Could not find parent \"NONEXISTENT\""
    end

    describe "graph structure" do
      it "has a root node" do
        expect(graph.root).to be_a Tenejo::PreFlightObj
      end

      it "root has at least 1 child for a valid CSV" do
        expect(graph.root.children.count).to be >= 1
      end

      it "connects collections without a parent in the CSV to the root" do
        expect(graph.root.children.map(&:identifier)).to include(["TESTINGCOLLECTION"])
      end

      it "connects works without a parent in the CSV to the root" do
        expect(graph.root.children.map(&:identifier)).to include(["MPC009"])
      end
    end
  end

  describe Tenejo::PFFile do
    let(:row) { {} }
    let(:rec) { described_class.new(row, 1, 'tmp/uploads') }
    it "is ok when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors[:resource_type]).to be_empty
      expect(rec.warnings[:resource_type]).to be_empty
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
      expect(rec.warnings[:resource_type]).to eq ["Resource Type \"foo\" is not recognized and will be omitted."]
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

  describe "assigns identifiers" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/file_id_test.csv", "tmp/uploads") }
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
        ace_of_spades = spades.files[0]
        expect(ace_of_spades.identifier).to eq ['CARDS-0001-S-A']
      end
      example "for files packed in a work", :aggregate_failures do
        king_of_clubs = clubs.files[3] # Arrays start at 0
        expect(king_of_clubs.identifier).to eq ['CARDS-0001-C.4'] # identifier indexes start at 1
      end
    end
    context "automatically when absent" do
      example "for single files" do
        jack_of_diamonds = diamonds.files[2]
        expect(jack_of_diamonds.identifier).to eq ["CARDS-0001-D//L10"]
      end
      example "for packed files" do
        queen_of_diamonds_back = diamonds.files[4]
        expect(queen_of_diamonds_back.identifier).to eq ["CARDS-0001-D//L11.2"]
      end
      example "for files packed in files" do
        ace_of_hearts = hearts.children[0].files[0]
        expect(ace_of_hearts.identifier).to eq ['CARDS-0001-H-A.1']
      end
    end
  end

  describe Tenejo::PFWork do
    let(:rec) { described_class.new({}, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new) }
    it "is not valid when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"], creator: ["can't be blank"]
      expect(rec.warnings).to include(visibility: ["Visibility on line 1 is blank - and will be treated as private"])
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
      expect(rec.warnings[:visibility]).to eq ["Visibility on line 1 is invalid: spoon - and will be treated as private"]
    end

    it "is ok to be blank" do
      rec.license = ''
      expect(rec.valid?).not_to eq true
      expect(rec.warnings[:license]).to be_empty
      expect(rec.license).to eq ""
    end

    it "restricts license" do
      rec = described_class.new({ license: 'foo' }, 1, Tenejo::DEFAULT_UPLOAD_PATH,  Tenejo::Graph.new)
      expect(rec.warnings[:license]).to eq ["License on line 1 is not recognized and will be left blank"]
      expect(rec.license).to eq []
    end

    it "discards extra license" do
      rec = described_class.new({ license: 'All rights reserved|~|Not validated' }, 1, Tenejo::DEFAULT_UPLOAD_PATH, Tenejo::Graph.new)
      expect(rec.license).to eq ['All rights reserved']
      expect(rec.warnings[:license]).to eq ["Multiple licenses on line 1: using 'All rights reserved' -- ignoring 'Not validated'"]
    end

    it "restricts rights statement" do
      expect(rec.valid?).not_to eq true
      expect(rec.warnings[:rights_statement]).to eq ["Rights Statement on line 1 not recognized or cannot be blank, and will be set to 'Copyright Undetermined'"]
      expect(rec.rights_statement).to eq ["Copyright Undetermined"]
    end

    it "restricts resource type" do
      rec.resource_type = ["foo"]
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type].join).to include "\"foo\" is not recognized and will be omitted."
    end

    it "can unpack" do
      p = Tenejo::PFFile.unpack({ files: "a|~|b|~|c", parent: 'p' }, 2, "tmp/uploads")
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
      expect(rec.warnings[:visibility]).to eq ["Visibility on line 1 has extra values: using 'public' -- ignoring: 'private, jet'"]
    end

    it "gives a warning if a controlled field has one or more invalid entries", :aggregate_failures do
      rec = described_class.new({ resource_type: "Poster|~|Airplane|~|Book|~|Bear" }, 1, Tenejo::DEFAULT_UPLOAD_PATH, 'placeholder for the graph')
      expect(rec.valid?).to eq false
      expect(rec.resource_type).to eq ["Poster", "Book"]
      expect(rec.warnings[:resource_type].join).to include "\"Airplane\" is not recognized and will be omitted."
      expect(rec.warnings[:resource_type].join).to include "\"Bear\" is not recognized and will be omitted."
    end
  end

  describe Tenejo::PFCollection do
    let(:rec) { described_class.new({}, 1) }
    it "is not valid when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"]
      expect(rec.warnings[:visibility]).to eq ["Visibility on line 1 is blank - and will be treated as private"]
    end

    it "restricts resource type" do
      rec.resource_type = ["foo"]
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type].join).to include "\"foo\" is not recognized and will be omitted."
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
