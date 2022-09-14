# frozen_string_literal: true
require 'rails_helper'
RSpec.describe Tenejo::Graph do
  context "when empty" do
    let(:g) { described_class.new }
    it "can serialize to json" do
      expect(g.to_json).not_to be_nil
      expect(JSON.parse(g.to_json)).not_to be_nil
      expect(JSON.parse(g.to_json).class).to eq Hash
    end
  end

  context "having loaded a file" do
    let(:g) {
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(/tiff/).and_return(true)
      Tenejo::Preflight.process_csv(File.open("./spec/fixtures/csv/nesting_test.csv"))
    }
    let(:flat) { g.flatten }

    let(:j) { Job.create!(user: FactoryBot.create(:user), graph: g) }

    it "empties out the detached files list after attaching them" do
      expect(g.detached_files).to be_empty
    end

    it "is able to reify after reload" do
      expect(j.reload.graph).to be_kind_of(described_class)
      expect(j.reload.graph.root).not_to be_nil
      expect(j.reload.graph.root).to be_kind_of(Tenejo::PreFlightObj)
      expect(j.reload.graph.root.children.first).to be_kind_of(Tenejo::PFWork)
      expect(j.reload.graph.root.children[2].children[0].children[0].children[0].children[0]).to be_kind_of(Tenejo::PFFile)
      expect(j.reload.graph.root.children[2]).to be_kind_of(Tenejo::PFCollection)
      expect(j.reload.graph.root.children.size).to eq 3
    end

    it "generates a flat list" do # rubocop:disable Metrics/BlockLength
      expect(flat.size).to eq 27
      expect(flat.shift.identifier).to eq ["ORPH-0001"]
      expect(flat.shift.identifier).to eq ["ORPH-0002"]
      expect(flat.shift.identifier).to eq ["EPHEM"]
      expect(flat.shift.identifier).to eq ["CARDS"]
      expect(flat.shift.identifier).to eq ["CARDS-0001"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-H"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-H"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-H-A"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-H-A.1"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-H-A.2"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-J"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-J.1"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-J.2"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-J.3"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-J.4"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-D"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-D-A.1"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-D-A.2"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-C"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-C.1"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-C.2"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-C.3"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-C.4"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-S"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-S-A"]
      expect(flat.shift.identifier).to eq ["CARDS-0001-S-J"]
      expect(flat.shift.identifier).to eq ["DARK"]
    end
  end
end
