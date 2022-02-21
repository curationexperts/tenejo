# frozen_string_literal: true
require 'rails_helper'

describe ApplicationHelper do
  it "can load random images " do
    expect(helper.random_image).not_to be_nil
    expect(helper.random_image).to match(/unsplash\/.*\.jpg/)
  end
end
