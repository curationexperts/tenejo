# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/index", type: :view do
  let(:user) { User.create(email: 'test@example.com', password: '123456') }
  let(:jobs) { [Job.create(user: user), Job.create(user: user)] }

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders a list of jobs", :aggregate_failures do
    @jobs = jobs
    render
    expect(rendered).to have_selector('tr th', text: 'ID')
    expect(rendered).to have_selector('tr th', text: 'Type')
    expect(rendered).to have_selector('tr th', text: 'User')
    expect(rendered).to have_selector('tr th', text: 'Status')
    expect(rendered).to have_selector('tr th', text: 'Completed')
    expect(rendered).to have_selector('tr th', text: 'Collections')
    expect(rendered).to have_selector('tr th', text: 'Works')
    expect(rendered).to have_selector('tr th', text: 'Files')
  end

  it "links the id to the show view" do
    @jobs = jobs
    render
    expect(rendered).to have_link(Job.last.id.to_s, href: url_for(Job.last))
  end
end
