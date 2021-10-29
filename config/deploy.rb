# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

require 'capistrano/passenger'
set :application, "cur"
set :repo_url, "git@github.com:curationexperts/cur.git"
set :ssh_options, keys: ["cur-cd"] if File.exist?("cur-cd")

set :deploy_to, '/opt/cur'
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
  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, :sidekiq
    end
  end
  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, :start, :sidekiq
    end
  end
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end