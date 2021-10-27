# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

## Prerequisites:

* ruby 2.7.4
* bundler 2.2.28
* Postgresql
* redis
* pwgen

## Getting started

Configure .env.development file, something like this:
```
PROJECT_NAME=cur
DATABASE_USERNAME=db_user
DATABASE_PASSWORD=<db_user password>
DATABASE_POOL_SIZE=25
SOLR_URL=http://localhost:8983/solr/hydra-development
FEDORA_DEV_URL=http://localhost:8984/rest
RAILS_SERVE_STATIC_FILES=true
SIDEKIQ_WORKERS=7
```
Create your databases:
```rails db:create```
Migrate the schema:
```rails db:migrate```

Start the servers (fedora, solr & puma)
``` rails hydra:server```

Install various bits & bobs:
```rails hyrax:default_admin_set:create```
```rails hyrax:workflow:load```
```rails hyrax:universal_viewer:install```

Create first user:
```rails cur:first_user```
This task will create an initial admin user with a random password, which will be the output of this task.
The default username is admin@example.com


If all went well, you should have a server up and runnint at http://localhost:3000
