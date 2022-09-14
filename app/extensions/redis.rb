# frozen_string_literal: true
require 'hyrax/redis_event_store'

Hyrax::RedisEventStore.class_eval do
  class << self
    def instance
      @redis ||= Redis::Namespace.new(namespace)
    end
  end
end
