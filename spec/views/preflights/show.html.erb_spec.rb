# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "preflights/show", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:completion_time) { Time.current.round }
  let(:job) {
    Preflight.new(
      id: 8_675_309,
      user: user,
      manifest: tempfile,
      status: :completed,
      completed_at: completion_time,
      works: 13,
      files: 17
    )
  }

  it "renders attributes", :aggregate_failures do
    @job = job
    @preflight_graph = {}
    render
    expect(rendered).to have_selector('#preflight-user', text: user)
    expect(rendered).to have_selector('#preflight-manifest', text: 'empty.csv')
    expect(rendered).to have_selector('#preflight-status', text: 'completed')
    expect(rendered).to have_selector('#preflight-created_at', text: job.created_at)
    expect(rendered).to have_selector('#preflight-completed_at', text: completion_time)
    expect(rendered).to have_selector('#preflight-collections', text: '--')
    expect(rendered).to have_selector('#preflight-works', text: '13')
    expect(rendered).to have_selector('#preflight-files', text: '17')
    expect(rendered).to have_link(text: 'empty.csv')
  end

  context "provides a 'Start Import' button" do
    it "with a valid Preflight ID", :aggregate_failures do
      @job = job
      @preflight_graph = { fatal_errors: [] }
      render
      expect(rendered).to have_button('Start Import', type: 'submit')
      assert_select 'input[id="import_parent_job_id"][value="8675309"]'
      assert_select 'form[action=?][method=?]', imports_path, 'post'
    end

    it "except when there are preflight errors" do
      @job = job
      @preflight_graph = { fatal_errors: ["No data was detected"] }
      render
      expect(rendered).to have_no_button('Start Import', type: 'submit')
    end
  end

  it "handles missing attributes gracefully" do
    @job = nil
    @preflight_graph = {}
    expect { render }.not_to raise_error
  end

  it "shows any errors" do
    @preflight_graph = { fatal_errors: ["No data was detected"] }
    render
    expect(rendered).to have_selector('.preflight-errors', text: 'No data was detected')
  end

  it "shows any warnings", :aggregate_failures do
    @preflight_graph = { warnings: ["Could not find parent work \"GONE?\" for file \"neverwhere.jpg\" on line 6", "Could not find parent work \"NONA\" for work \"MPC009\" on line 11"] }
    render
    expect(rendered).to have_selector('.preflight-warnings', text: 'Warnings')
    expect(rendered).to have_selector('li', text: 'Could not find parent work', count: 2)
  end

  it "shows any collections", :aggregate_failures do
    CollectionDummy = Struct.new(:lineno, :visibility, :identifier, :title, keyword_init: true)
    @preflight_graph = {
      collection: [
        CollectionDummy.new(title: 'Collection 1', lineno: 2),
        CollectionDummy.new(title: 'Collection 2', lineno: 3)
      ]
    }
    render
    expect(rendered).to have_selector('.preflight-collections', text: 'Collections')
    expect(rendered).to have_selector('tr td', text: 'Collection 2')
  end

  it "shows any works", :aggregate_failures do
    PFPlaceholder = Struct.new(:lineno, :visibility, :identifier, :title, keyword_init: true)
    @preflight_graph = {
      work: [
        PFPlaceholder.new(title: 'Work 1', lineno: 5),
        PFPlaceholder.new(title: 'Work 2', lineno: 7)
      ]
    }
    render
    expect(rendered).to have_selector('.preflight-works', text: 'Works')
    expect(rendered).to have_selector('tr td', text: 'Work 2')
  end

  it "shows any files", :aggregate_failures do
    FileDummy = Struct.new(:lineno, :parent, :import_path, :file, keyword_init: true)
    @preflight_graph = {
      file: [
        FileDummy.new(file: 'hydra.tiff', lineno: 8),
        FileDummy.new(file: 'hydra.tiff', lineno: 4)
      ]
    }
    render
    expect(rendered).to have_selector('.preflight-files', text: 'Files')
    expect(rendered).to have_selector('tr td', text: 'hydra.tiff', count: 2)
  end
end
