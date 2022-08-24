# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "imports/show", type: :view do
  let(:admin) { FactoryBot.create(:user) }
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:completion_time) { Time.current.round }
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
  let(:import_job) { Import.create!(user: admin, parent_job: preflight, graph: Tenejo::Preflight.process_csv(preflight.manifest.download)) }

  it "renders attributes", :aggregate_failures do
    @job = import_job
    @root = {}
    render
    expect(rendered).to have_selector('.jobs-user', text: admin)
    expect(rendered).to have_selector('.jobs-status', text: 'Unknown')
    expect(rendered).to have_selector('.jobs-created_at', text: import_job.created_at)
    expect(rendered).to have_selector('.jobs-completed_at', text: '--')
    expect(rendered).to have_selector('.jobs-collections', text: 'N/A')
    expect(rendered).to have_selector('.jobs-works', text: 'N/A')
    expect(rendered).to have_selector('.jobs-files', text: 'N/A')
    expect(rendered).to have_link(text: 'empty.csv')
  end

  it "handles missing attributes gracefully" do
    @job = nil
    @root = {}
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
