# frozen_string_literal: true
module Hyrax
  # These are the metadata elements that Hyrax internally requires of
  # all managed Collections, Works and FileSets will have.
  module BasicMetadata
    extend ActiveSupport::Concern

    included do
      include Tenejo::BasicMetadata
    end
  end
end
