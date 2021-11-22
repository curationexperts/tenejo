# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "jobs/index", type: :view do
  let(:user) { User.create(email: 'test@example.com', password: '123456') }
  before do
    assign(:jobs, [
             Job.create!(
               type: nil,
               label: "Label",
               user: user,
               status: "Status",
               collections: 2,
               works: 3,
               files: 4
             ),
             Job.create!(
               type: nil,
               label: "Label",
               user: user,
               status: "Status",
               collections: 2,
               works: 3,
               files: 4
             )
           ])
  end

  # Scaffold generated test - should be replaced when additional functionality is developed
  it "renders a list of jobs" do
    render
    assert_select "tr>td", text: "Label".to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 4
    assert_select "tr>td", text: "Status".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: 4.to_s, count: 2
  end
end
