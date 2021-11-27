# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "preflights/show", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:tempfile) { fixture_file_upload('csv/empty.csv') }
  let(:completion_time) { Time.current.round }
  let(:job) {
    Preflight.new(
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

  it "handles missing attributes gracefully" do
    @job = nil
    expect { render }.not_to raise_error
  end
end
