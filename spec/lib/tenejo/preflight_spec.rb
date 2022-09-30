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
end
