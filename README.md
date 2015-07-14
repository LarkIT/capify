# capify
Our default/basic Capistrano configuration

This is just our template for deploying rails applications to our default hosting configuration.

USE AT YOUR OWN RISK!

## How To

* Download the latest zip file (see ZIP button above)
* Unzip into your "rails root"
* Add the following to your Gemfile
```
# Capistrano Deployment
group :development, :deployment do
  gem 'capistrano', '3.4.0', require: false  #deploy is locked to this version
  gem 'capistrano-rails', '~> 1.1.3', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-faster-assets', '~> 1.0', require: false
  gem 'capistrano-db-tasks', '~> 1.0', require: false
end
```

* Customize as necessary, hint you need to set servers in `config/deploy/ENVIRONMENT.rb`
