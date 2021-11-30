# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "themes/edit", type: :view do
  before do
    @theme = assign(:theme, Theme.create!(
      site_title: "MyString",
      primary_color: "MyString",
      accent_color: "MyString",
      primary_text_color: "MyString",
      accent_text_color: "MyString",
      background_color: "MyString"
    ))
  end

  it "renders the edit theme form" do
    render

    assert_select "form[action=?][method=?]", theme_path, "post" do
      assert_select "input[name=?]", "theme[site_title]"

      assert_select "input[name=?]", "theme[primary_color]"

      assert_select "input[name=?]", "theme[accent_color]"

      assert_select "input[name=?]", "theme[primary_text_color]"

      assert_select "input[name=?]", "theme[accent_text_color]"

      assert_select "input[name=?]", "theme[background_color]"
    end
  end
end
