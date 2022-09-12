# frozen_string_literal: true
require 'active_fedora/with_metadata/default_metadata_class_factory'

ActiveFedora::WithMetadata::DefaultMetadataClassFactory.class_eval do
  class << self
    private

    def create_class(parent_klass)
      Class.new(metadata_base_class).tap do |klass|
        parent_klass.send(:remove_const, :GeneratedMetadataSchema) if parent_klass.const_defined?(:GeneratedMetadataSchema)
        parent_klass.const_set(:GeneratedMetadataSchema, klass)
        klass.parent_class = parent_klass
      end
    end
  end
end
