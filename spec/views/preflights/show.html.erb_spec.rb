# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "preflights/show", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:completion_time) { Time.current.round }
  let(:graph) { Tenejo::Graph.new }
  let(:job) {
    Preflight.new(
      id: 8_675_309,
      user: user,
      manifest: tempfile,
      status: :completed,
      completed_at: completion_time,
      collections: '0',
      works: 13,
      files: 17
    )
  }

  it "renders attributes", :aggregate_failures do
    assign(:job, job)
    @preflight_graph = Tenejo::Graph.new
    render
    expect(rendered).to have_selector('.job-user', text: user)
    expect(rendered).to have_selector('.job-manifest', text: 'empty.csv')
    expect(rendered).to have_selector('.job-status', text: 'Completed')
    expect(rendered).to have_selector('.job-created_at', text: job.created_at)
    expect(rendered).to have_selector('.job-completed_at', text: completion_time)
    expect(rendered).to have_selector('.job-collections', text: '0')
    expect(rendered).to have_selector('.job-works', text: '13')
    expect(rendered).to have_selector('.job-files', text: '17')
    expect(rendered).to have_link(text: 'empty.csv')
  end

  context "provides a 'Start Import' button" do
    it "with a valid Preflight ID", :aggregate_failures do
      assign(:job, job)
      assign(:preflight_graph, graph)
      render
      expect(rendered).to have_button('Start Import', type: 'submit')
      assert_select 'input[id="import_parent_job_id"][value="8675309"]'
      assert_select 'form[action=?][method=?]', imports_path, 'post'
    end

    it "except when there are preflight errors" do
      assign(:job, job)
      graph.add_fatal_error("No data was detected")
      assign(:preflight_graph, graph)
      render
      expect(rendered).to have_no_button('Start Import', type: 'submit')
    end
  end

  it "handles missing attributes gracefully" do
    assign(:job, job)
    assign(:preflight_graph, graph)
    expect { render }.not_to raise_error
  end

  it "shows any errors" do
    graph.add_fatal_error "No data was detected"
    assign(:preflight_graph, graph)
    render
    expect(rendered).to have_selector('#preflight-errors li', text: 'No data was detected')
  end

  it "shows any warnings", :aggregate_failures do
    graph.add_warning("Could not find parent work \"GONE?\" for file \"neverwhere.jpg\" on line 6")
    graph.add_warning("Could not find parent work \"NONA\" for work \"MPC009\" on line 11")
    assign(:preflight_graph, graph)
    assign(:job, job)
    render
    expect(rendered).to have_selector('#preflight-warnings', text: 'Warnings')
    expect(rendered).to have_selector('li', text: 'Could not find parent work', count: 2)
  end

  it "shows any collections", :aggregate_failures do
    CollectionDummy = Struct.new(:lineno, :visibility, :identifier, :title, keyword_init: true)
    graph.collections << CollectionDummy.new(title: 'Collection 1', lineno: 2)
    graph.collections << CollectionDummy.new(title: 'Collection 2', lineno: 3)
    assign(:preflight_graph, graph)
    assign(:job, job)
    render
    expect(rendered).to have_selector('#preflight-collections', text: 'Collections')
    expect(rendered).to have_selector('tr td', text: 'Collection 2')
  end

  it "shows any works", :aggregate_failures do
    PFPlaceholder = Struct.new(:lineno, :visibility, :identifier, :title, keyword_init: true)
    graph.works << PFPlaceholder.new(title: 'Work 1', lineno: 5)
    graph.works << PFPlaceholder.new(title: 'Work 2', lineno: 7)
    assign(:preflight_graph, graph)
    assign(:job, job)
    render
    expect(rendered).to have_selector('#preflight-works', text: 'Works')
    expect(rendered).to have_selector('tr td', text: 'Work 2')
  end

  it "shows any files", :aggregate_failures do
    FileDummy = Struct.new(:lineno, :parent, :import_path, :file, :visibility, keyword_init: true)
    graph.files << FileDummy.new(file: 'hydra.tiff', lineno: 8, visibility: :open)
    graph.files << FileDummy.new(file: 'hydra.tiff', lineno: 4, visibility: :restricted)
    assign(:preflight_graph, graph)
    assign(:job, job)
    render
    expect(rendered).to have_selector('#preflight-files', text: 'Files')
    expect(rendered).to have_selector('tr td', text: 'hydra.tiff', count: 2)
  end
end
