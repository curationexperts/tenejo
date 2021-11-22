# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/show", type: :view do
  let(:user) { User.create(email: 'test@example.com', password: '123456') }
  before do
    @job = assign(:job, Job.create!(
      type: nil,
      label: "Label",
      user: user,
      status: "Status",
      collections: 2,
      works: 3,
      files: 4
    ))
  end

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Type/)
    expect(rendered).to match(/Label/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
  end
end
