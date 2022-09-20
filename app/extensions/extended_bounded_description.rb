# frozen_string_literal: true
require 'active_triples/util/extended_bounded_description'

ActiveTriples::ExtendedBoundedDescription.class_eval do
  # @param source_graph  [RDF::Queryable]
  # @param starting_node [RDF::Term]
  # @param ancestors     [Array<RDF::Term>] default: []
  def initialize(source_graph, starting_node, ancestors = [])
    @source_graph  = source_graph
    @starting_node = starting_node
    @ancestors     = Set.new(*ancestors) # Replaces array in original implementation
  end

  # Replaces original recursive method with iterative implementation
  def each_statement
    if block_given?
      nodes_to_process = [] << starting_node

      while nodes_to_process.any?
        current_node = nodes_to_process.pop
        ancestors << current_node
        statements = source_graph.query(subject: current_node).each
        statements.each_statement do |statement|
          yield statement
          object = statement.object
          nodes_to_process.push(object) unless object.literal? || ancestors.include?(object)
        end
      end

    end # block given
    enum_statement
  end

  alias_method :each, :each_statement
end
