# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'devise'
require_relative 'support/controller_macros'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rails'
require 'noid/rails/rspec'

# default to running background jobs in test mode
require "sidekiq/testing"

# use this in specs to avoid actually using a working virus scanner during tests (very slow)
Hyrax.config.virus_scanner = Hyrax::VirusScanner

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

Rails.application.routes.default_url_options[:host] = 'localhost:3000'

RSpec.configure do |config|
  # Enable sign_in and sign_out functionality in specs
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Avoid rollback of id minter-state to avoid errors like
  # `Ldp::Conflict, "Can't call create on an existing resource"`
  # see testing notes at https://github.com/samvera/noid-rails#overriding-default-behavior
  include Noid::Rails::RSpec
  config.before(:suite) { disable_production_minter! }
  config.after(:suite)  { enable_production_minter! }

  # Clean out ActiveFedora
  config.before(:suite) { ActiveFedora::Cleaner.clean! }

  config.before do |_example|
    class_double(Tenejo::VirusScanner)
    allow(Tenejo::VirusScanner).to receive(:infected?).and_return(false)
    allow(Tenejo::VirusScanner).to receive(:infected?).and_return(true)
  end

  # Ensure a default Theme exists for all tests
  config.before(:suite) { Theme.where(id: 1).first_or_create! }

  # Delete any ActiveStorage files created during test runs
  config.after(:suite) { FileUtils.rm_rf(ActiveStorage::Blob.service.root) }

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.extend ControllerMacros, type: :controller

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
