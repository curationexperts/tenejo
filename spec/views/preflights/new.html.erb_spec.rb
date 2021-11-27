# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "preflights/new", type: :view do
  it 'shows the expected preflight form fields', :aggregate_failures do
    @job = Preflight.new
    render
    expect(rendered).to have_selector('h1', text: 'New Preflight')
    expect(rendered).to have_field('preflight[manifest]', type: 'file')
    expect(rendered).to have_button('Submit', type: 'submit')
    assert_select 'form[action=?][method=?]', preflights_path, 'post'
  end

  it 'renders form errors' do
    job_with_errors = Preflight.new
    job_with_errors.errors.messages[:fake] << 'error message'
    @job = job_with_errors
    render
    expect(rendered).to have_selector('#error_explanation', text: 'Fake error message')
  end
end
