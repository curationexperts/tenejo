# frozen_string_literal: true
module Hyrax
  class WorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::Work
    self.required_fields += [:identifier]
    self.terms += [:resource_type, :other_identifiers]
  end
end
