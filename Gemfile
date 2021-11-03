# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.6'
gem 'sidekiq', '~> 6.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.3.0'
# Use Puma as the app server
gem 'dotenv-rails', '~> 2.2.1'
gem 'okcomputer'
gem 'pg', '~> 1.0'
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

gem "clamby"
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'hydra-role-management', '~> 1.0', '>= 1.0.3'
gem 'hyrax', '3.1.0'

gem 'bootstrap-sass', '~> 3.0'
gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'devise_invitable', '~> 2.0.0'
gem 'honeybadger', group: 'production'
gem 'jquery-rails'
gem 'riiif', '~> 2.1'
gem 'rsolr', '>= 1.0', '< 3'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'whenever', group: 'production'

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
  gem 'webdrivers'
end

group :development, :test do
  gem 'bixby', '~> 3.0'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-sidekiq'
  gem 'fcrepo_wrapper'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'solr_wrapper', '>= 0.3'
  gem 'xray-rails', '~> 0.3.2'
end
