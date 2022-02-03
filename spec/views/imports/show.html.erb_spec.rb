# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "imports/show", type: :view do
  let(:admin) { FactoryBot.create(:user) }
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:completion_time) { Time.current.round }
  let(:import_job) { Import.new(user: admin, parent_job: preflight) }
  let(:preflight) {
    Preflight.new(
      id: 8_675_309,
      user: admin,
      manifest: tempfile,
      status: :completed,
      completed_at: completion_time,
      works: 13,
      files: 17
    )
  }

  it "renders attributes", :aggregate_failures do
    @job = import_job
    @root = Tenejo::Graph.new.root
    render
    expect(rendered).to have_selector('#import-user', text: admin)
    expect(rendered).to have_selector('#import-manifest', text: 'empty.csv')
    expect(rendered).to have_selector('#import-status', text: 'Unknown')
    expect(rendered).to have_selector('#import-created_at', text: import_job.created_at)
    expect(rendered).to have_selector('#import-completed_at', text: '--')
    expect(rendered).to have_selector('#import-collections', text: '--')
    expect(rendered).to have_selector('#import-works', text: '--')
    expect(rendered).to have_selector('#import-files', text: '--')
    expect(rendered).to have_link(text: 'empty.csv')
  end

  it "handles missing attributes gracefully" do
    @job = nil
    @root = Tenejo::Graph.new.root
    expect { render }.not_to raise_error
  end

  it "shows any errors" do
    pending "accumulate import errors"
    render
    expect(rendered).to have_selector('.import-errors', text: 'Virus detected')
  end

  it "shows any warnings", :aggregate_failures do
    pending "accumulate import warnings"
    render
    expect(rendered).to have_selector('.import-warnings', text: 'Warnings')
    expect(rendered).to have_selector('li', text: 'Could not find parent work', count: 2)
  end

  it "shows any collections", :aggregate_failures do
    pending "Finalize import/show UI layout"
    expect(rendered).to have_selector('tr td', text: 'Collection...')
  end

  it "shows any works", :aggregate_failures do
    pending "Finalize import/show UI layout"
    expect(rendered).to have_selector('tr td', text: 'Work...')
  end

  it "shows any files", :aggregate_failures do
    pending "Finalize import/show UI layout"
    expect(rendered).to have_selector('tr td', text: 'File...')
  end
end