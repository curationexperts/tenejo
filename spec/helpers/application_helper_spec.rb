# frozen_string_literal: true
require 'rails_helper'

describe ApplicationHelper do
  it "can load random images " do
    expect(helper.random_image).not_to be_nil
    expect(helper.random_image).to match(/unsplash\/.*\.jpg/)
  end

  context "#status_span_generator" do
    example "for known statuses" do
      expect(helper.status_span_generator('submitted')).to include "Submitted"
    end

    example "for unrecognized statuses" do
      expect(helper.status_span_generator("it's complicated")).to include "-?-"
    end

    example "accepts symbols" do
      expect(helper.status_span_generator(:in_progress)).to include "In Progress"
    end
  end
end
