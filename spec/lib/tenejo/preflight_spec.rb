# frozen_string_literal: true
require 'rails_helper'
require 'fileutils'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Tenejo::Preflight do
  before :all do
    FileUtils.mkdir_p("tmp/uploads")
  end
  after :all do
    FileUtils.rm_r("tmp/uploads")
  end

  context '.process_csv' do
    let(:no_data) { described_class.process_csv(nil, nil) }
    it 'returns an error when input stream absent' do
      expect(no_data[:fatal_errors]).to include "No manifest present"
    end
  end

  context "a file with duplicate columns" do
    let(:dupes) { described_class.read_csv("spec/fixtures/csv/dupe_col.csv", "tmp/uploads") }

    it "records fatal error for duplicate column " do
      expect(dupes[:fatal_errors]).to include "Duplicate column names detected [:identifier, :identifier, :title, :title], cannot process"
    end
  end
  context "a file that isn't a csv " do
    let(:graph) { described_class.read_csv("spec/fixtures/images/tiny.jpg", "tmp/uploads") }
    it "returns a fatal error" do
      expect(graph[:fatal_errors]).to eq ["File format or encoding not recognized"]
    end
  end
  context "a file with no data" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/empty.csv", "tmp/uploads") }
    it "returns an empty graph" do
      [:work, :collection, :file].each do |x|
        expect(graph[x]).to be_empty
      end
    end
    it "records toplevel errors" do
      expect(graph[:fatal_errors]).to eq ["No data was detected"]
      expect(graph[:warnings]).to be_empty
    end
  end

  context "a file that has unmapped header names" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/unmapped.csv", "tmp/uploads") }
    it "records a warning for that row" do
      expect(graph[:warnings]).to include "The column \"frankabillity\" is unknown, and will be ignored"
    end
  end

  context "a row with too many columns" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/missing_cols.csv", "tmp/uploads") }
    it "records a warning for that row" do
      expect(graph[:warnings]).to eq ["The number of columns in row 2 differed from the number of headers (missing quotation mark?)"]
    end
  end

  context "a file with a bad object type" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/bad_ot.csv", "tmp/uploads") }

    it "records a warning for that row" do
      expect(graph[:warnings]).to eq ["Uknown object type on row 2: potato"]
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
  context "a well formed file" do
    let(:graph) { described_class.read_csv("spec/fixtures/csv/fancy.csv", "tmp/uploads") }

    it "checks for missing files in IMPORT_PATH" do
      expect(graph[:file].first.valid?).to be false
      expect(graph[:file].first.errors[:file]).to include "Could not find file MN-02 2.png at tmp/uploads"
    end

    it "records line number" do
      expect(graph[:work].first.lineno).to eq 4
      expect(graph[:collection].first.lineno).to eq 2
      expect(graph[:file].first.lineno).to eq 5
    end

    it "connects files with parents" do
      expect(graph[:work].first.files.map(&:file)).to eq ['MN-02 2.png', 'MN-02 3.png']
      expect(graph[:work][1].files.map(&:file)).to eq ["MN-02 4.png"]
    end
    it "connects works with works" do
      expect(graph[:work][1].children.map(&:identifier)).to eq [["MPC008"]]
    end
    it "warns about disconnected  works" do
      expect(graph[:warnings]).to include "Could not find parent work \"NONA\" for work \"MPC009\" on line 10"
    end
    it "connects works and collections with parents" do
      expect(graph[:collection].size).to eq 2
      expect(graph[:collection].first.children.map(&:identifier)).to eq [["MPC002"], ["MPC003"]]
      expect(graph[:collection].last.children.map(&:identifier)).to be_empty
    end
    it "warns when work has no parent" do
      expect(graph[:warnings]).to include "Could not find parent work \"NONEXISTENT\" for work \"NONACOLLECTION\" on line 3"
    end
    it "warns files without parent in sheet" do
      expect(graph[:warnings]).to include "Could not find parent work \"WHUT?\" for file \"MN-02 2.whut\" on line 6"
    end

    it "parses out object types" do
      expect(graph[:work].size).to eq 4
      expect(graph[:collection].size).to eq 2
      expect(graph[:file].size).to eq 4
    end

    it "has validation" do
      FileUtils.touch("tmp/uploads/MN-02 4.png")
      [:work, :collection].each do |x|
        graph[x].each do |y|
          expect(y.valid?).to eq true
        end
      end
      expect(graph[:file].first.valid?).to be false
      expect(graph[:file].last.valid?).to be true
    end
  end
  describe Tenejo::PFFile do
    let(:rec) { described_class.new({}, 1, 'tmp/uploads') }
    it "is ok when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors[:resource_type]).to be_empty
      expect(rec.warnings[:resource_type]).to be_empty
    end

    it "restricts resource type" do
      rec.resource_type = "foo"
      expect(rec.valid?).to eq false # there are other errors in the example
      expect(rec.warnings[:resource_type]).to eq ["Resource type \"foo\" on line 1 is not recognized and will be left blank."]
    end
  end
  describe Tenejo::PFWork do
    let(:rec) { described_class.new({}, 1) }
    it "is not valid when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"], creator: ["can't be blank"], visibility: ["can't be blank"]
    end
    it "transforms visibility" do
      rec = described_class.new({ visibility: 'Public' }, 1)
      expect(rec.visibility).to eq :open
      rec = described_class.new({ visibility: 'Authenticated' }, 1)
      expect(rec.visibility).to eq :registered
      rec = described_class.new({ visibility: 'PrIvAte' }, 1)
      expect(rec.visibility).to eq :restricted
    end
    it "validates visibility" do
      rec = described_class.new({ visibility: 'spoon' }, 1)
      expect(rec.visibility).to eq :spoon
      expect(rec.valid?).not_to eq true
      expect(rec.errors[:visibility]).to eq ["Unknown visibility \"spoon\" on line 1"]
    end

    it "is ok to be blank" do
      rec.license = ''
      expect(rec.valid?).not_to eq true
      expect(rec.warnings[:license]).to be_empty
      expect(rec.license).to eq ""
    end

    it "restricts license" do
      rec = described_class.new({ license: 'foo' }, 1)
      expect(rec.warnings[:license]).to eq ["License on line 1 is not recognized and will be left blank"]
      expect(rec.license).to eq []
    end

    it "discards extra license" do
      rec = described_class.new({ license: 'All rights reserved|~|Not validated' }, 1)
      expect(rec.license).to eq ['All rights reserved']
      expect(rec.warnings[:license]).to eq ["Multiple licenses on line 1: using 'All rights reserved' -- ignoring 'Not validated'"]
    end

    it "restricts rights statement" do
      expect(rec.valid?).not_to eq true
      expect(rec.warnings[:rights_statement]).to eq ["Rights Statement on line 1 not recognized or cannot be blank, and will be set to 'Copyright Undetermined'"]
      expect(rec.rights_statement).to eq ["Copyright Undetermined"]
    end

    it "can unpack" do
      p = Tenejo::PFFile.unpack({ files: "a|~|b|~|c", parent: 'p' }, 2, "tmp/uploads")
      expect(p).to be_an Array
      expect(p.size).to eq 3
      expect(p.first.file).to eq "a"
      expect(p.last.file).to eq "c"
    end

    it "unpacks multi-valued fields" do
      rec = described_class.new({ keyword: "Lions|~|Tigers|~|Bears" }, 1)
      expect(rec.keyword).to eq ["Lions", "Tigers", "Bears"]
    end

    it "wraps multi-value fields in an array", :aggregate_failures do
      rec = described_class.new({ title: "Have a nice day", visibility: "public" }, 1)
      expect(rec.title).to eq ["Have a nice day"]
      expect(rec.visibility).to eq :open # example of singular field not in an array
    end

    it "gives a warning if a single-valued field has packed data" do
      rec = described_class.new({ visibility: "public|~|private|~|jet" }, 1)
      expect(rec.visibility).to eq :open
      expect(rec.warnings[:visibility]).to eq ["Visibility on line 1 has extra values: using 'public' -- ignoring: 'private, jet'"]
    end

    it "gives a warning if a controlled field has one or more invalid entries" do
      pending "TODO: figure out how multiples and validations should interact"
      rec = described_class.new({ resource_type: "Poster|~|Airplane|~|Book|~|Bear" }, 1)
      expect(rec.resource_type).to eq ["Poster", "Book"]
      expect(rec.warnings[:resource_type]).to eq ["Resource Type on line 1 contains invalid values, 'Airplane' & 'Bear' will be ignored"]
    end
  end

  describe Tenejo::PFCollection do
    let(:rec) { described_class.new({}, 1) }
    it "is not valid when blank" do
      expect(rec.valid?).not_to eq true
      expect(rec.errors.messages).to eq identifier: ["can't be blank"],
        title: ["can't be blank"], visibility: ["can't be blank"]
    end
  end
end
