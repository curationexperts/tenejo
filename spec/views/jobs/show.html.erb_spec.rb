# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/show", type: :view do
  let(:user) { User.create(email: 'test@example.com', password: '123456') }

  let(:job) {
    @job = Job.create!(
       type: nil,
       label: "test job",
       user: user,
       status: :completed,
       graph: Tenejo::Graph.new
     )
  }

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders attributes in <p>" do
    expect(job.graph).to have_received(:collections).and_return(Array.new(11))
    expect(job.graph).to have_received(:works).and_return(Array.new(13))
    expect(job.graph).to have_received(:files).and_return(Array.new(17))
    assign(:job, job)
    render
    expect(rendered).to match('Type')
    expect(rendered).to match('Label')
    expect(rendered).to match('test job')
    expect(rendered).to match('Status')
    expect(rendered).to match('completed')
    expect(rendered).to match('11')
    expect(rendered).to match('13')
    expect(rendered).to match('17')
  end
end
