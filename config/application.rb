# frozen_string_literal: true
require_relative 'boot'

require 'rails/all'
require 'deprecation'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Deprecation.default_deprecation_behavior = :silence
Bundler.require(*Rails.groups)

module Tenejo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.active_job.queue_adapter = :sidekiq
    Rails.application.routes.default_url_options[:host] = ENV['URL_HOST']
    config.exceptions_app = self.routes
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
