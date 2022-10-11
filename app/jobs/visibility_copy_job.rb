# frozen_string_literal: true
# Responsible for copying the following attributes from the work to each file in the file_sets
#
# * visibility
# * lease
# * embargo
class VisibilityCopyJob < Hyrax::ApplicationJob
  # @api public
  # @param [Hyrax::WorkBehavior, Hyrax::Resource] work - a Work model,
  #   using ActiveFedora or Valkyrie
  def perform(work)
    propagator = Hyrax::VisibilityPropagator.for(source: work)
    if propagator.respond_to?(:propogate)
      propagator.propogate
    else
      propagator.propagate
    end
  end
end
