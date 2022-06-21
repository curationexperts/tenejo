# frozen_string_literal: true
class ServletCharacterizationService < Hydra::Works::CharacterizationService
  def initialize(object, source, options)
    @object       = object
    @source       = source
    @mapping      = options.fetch(:parser_mapping, Hydra::Works::Characterization.mapper)
    @parser_class = options.fetch(:parser_class, Hydra::Works::Characterization::FitsDocument)
    @tools        = options.fetch(:ch12n_tool, :fits_servlet)
  end
end
