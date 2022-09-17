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
      completed_at: completion_time
    )
  }
  let(:import_job) { Import.create!(user: admin, parent_job: preflight, graph: Tenejo::Graph.new, status: :submitted) }

  it "renders attributes", :aggregate_failures do
    @job = import_job
    @root = {}
    render
    expect(rendered).to have_selector('.job-user', text: admin)
    expect(rendered).to have_selector('.job-status', text: 'Submitted')
    expect(rendered).to have_selector('.job-created_at', text: import_job.created_at)
    expect(rendered).to have_selector('.job-completed_at', text: '–')
    expect(rendered).to have_selector('.job-collections', text: '–')
    expect(rendered).to have_selector('.job-works', text: '–')
    expect(rendered).to have_selector('.job-files', text: '–')
    expect(rendered).to have_link(text: 'empty.csv')
  end

  it "handles missing attributes gracefully" do
    @job = nil
    assign(:job, import_job)
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
    expect(rendered).to have_selector('dt', text: 'Collections')
  end

  it "shows any works", :aggregate_failures do
    pending "Finalize import/show UI layout"
    expect(rendered).to have_selector('dt', text: 'Works')
  end

  it "shows any files", :aggregate_failures do
    pending "Finalize import/show UI layout"
    expect(rendered).to have_selector('dt', text: 'Files')
  end
end
