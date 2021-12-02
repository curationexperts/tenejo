# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

require 'capistrano/passenger'
set :application, "tenejo"
set :repo_url, 'https://github.com/curationexperts/tenejo'
set :ssh_options, keys: ["tenejo-cd"] if File.exist?("tenejo-cd")

set :deploy_to, '/opt/tenejo'
set :rails_env, 'production'
set :log_level, :warn
set :bundle_env_variables, nokogiri_use_system_libraries: 1

set :keep_releases, 5
set :assets_prefix, "#{shared_path}/public/assets"

SSHKit.config.command_map[:rake] = 'bundle exec rake'

set :branch, ENV['REVISION'] || ENV['BRANCH'] || ENV['BRANCH_NAME'] || 'main'

append :linked_dirs, "log"
append :linked_dirs, "public/assets"
append :linked_dirs, "tmp/pids"
append :linked_dirs, "tmp/cache"
append :linked_dirs, "tmp/sockets"

append :linked_files, ".env.production"
append :linked_files, "config/secrets.yml"

namespace :sidekiq do
  task :quiet do
    on roles(:app) do
      puts capture("pgrep -f 'sidekiq' | xargs kill -TSTP")
    end
  end
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end

after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'
