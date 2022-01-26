# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Work`
module Hyrax
  # Generated form for Work
  class WorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::Work
    self.required_fields += [:primary_identifier]
    self.terms += [:resource_type]
  end
end
