# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'bcrypt_pbkdf'
gem 'ed25519'
gem 'rails', '~> 5.2.7'
gem 'sidekiq', '~> 6.4'
# Use Puma as the app server
gem 'dotenv-rails', '~> 2.2.1'
gem 'okcomputer'
gem 'pg', '~> 1.0'
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'terser'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'hydra-role-management', '~> 1.0', '>= 1.0.3'
gem 'hyrax'

gem 'bootstrap-sass', '~> 3.0'
gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'devise_invitable', '~> 2.0.0'
gem 'honeybadger', group: 'production'
gem 'jquery-rails'
gem 'riiif', '~> 2.1'
gem 'rsolr', '>= 1.0', '< 3'
gem 'whenever', group: 'production'

group :test do
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'simplecov_json_formatter'
  gem 'webdrivers'
end

group :development, :test do
  gem 'bixby', '~> 3.0'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'fcrepo_wrapper'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'solr_wrapper', '>= 0.3'
  gem 'xray-rails', '~> 0.3.2'
end
