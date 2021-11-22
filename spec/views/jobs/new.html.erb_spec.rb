# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/new", type: :view do
  before do
    assign(:job, Job.new(
      type: nil,
      label: "MyString",
      user: nil,
      status: "MyString",
      collections: 1,
      works: 1,
      files: 1
    ))
  end

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders new job form" do
    render

    assert_select "form[action=?][method=?]", jobs_path, "post" do
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
