# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/edit", type: :view do
  let(:user) { User.create(email: 'test@example.com', password: '123456') }
  let(:job) {
    assign(:job, Job.create!(
      type: nil,
      label: "MyString",
      user: user,
      status: "MyString",
      collections: 1,
      works: 1,
      files: 1
    ))
  }

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders the edit job form" do
    job
    render

    assert_select "form[action=?][method=?]", job_path(job), "post" do
      assert_select "input[name=?]", "job[type]"
      assert_select "input[name=?]", "job[label]"
      assert_select "input[name=?]", "job[user_id]"
      assert_select "input[name=?]", "job[status]"
      assert_select "input[name=?]", "job[collections]"
      assert_select "input[name=?]", "job[works]"
      assert_select "input[name=?]", "job[files]"
    end
  end
end
