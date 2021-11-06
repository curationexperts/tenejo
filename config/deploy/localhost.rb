# frozen_string_literal: true
set :repo_url, 'https://github.com/curationexperts/cur'
server '127.0.0.1', user: 'deploy', roles: [:web, :app, :db]