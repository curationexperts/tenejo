# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/new", type: :view do
  it 'gives links to job subclasses' do
    Job1Type = Class.new(Job)
    Job2Type = Class.new(Job)
    render
    expect(rendered).to have_link('New Job1Type', href: '/job1types/new')
    expect(rendered).to have_link('New Job2Type', href: '/job2types/new')
  end
end
