# config valid only for current version of Capistrano
lock '3.4.0'
require 'colorize'

# GIT Repo URL
set :repo_url, "git@github.com:ORGANIZATION/REPOSITORY.git"

# Ruby Version (used for RVM) - MUST MATCH PASSENGER/SERVER CONFIG!
set :ruby_version, '2.2.0'

# Application name (default to using "railsapp")
#   -- determines deploy path and user
set :application, 'railsapp'

## Bundler ENV
set :bundle_env_variables, {
        QMAKE: 'qmake-qt4',
}

## Global SSH Options
set :ssh_options, {
  forward_agent: true,
  port: 1022,
  keepalive: true,
  keepalive_interval: 60, #seconds - prevents idle timeouts on long tasks
}

# Determine Rails Environment
rails_envs = %w[ development integration staging qa production ]
cap_stage = fetch(:stage).to_s
if rails_envs.include? cap_stage
  set :rails_env, fetch(:stage)
else
  set :rails_env, 'development'
end

# Other Rails Settings
set :migration_role, :app
set :conditionally_migrate, true
set :assets_roles, [:web, :app]
set :normalize_asset_timestamps, false

# Default to current branch (unless overridden in stages)
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :current_branch, :branch

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, ->{ "/web/#{fetch(:application)}/#{fetch(:rails_env)}" }

# Default value for :scm is :git
set :scm, :git
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug, lets use :info to quiet it down
set :log_level, :info

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
        'config/database.yml',
        'config/secrets.yml',
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
        'log',
        'tmp/pids',
        'tmp/cache',
        'tmp/sockets',
        'vendor/bundle',
        'public/system',
        #'public/assets', ## included by capistrano/rails/assets
)

# DB / Asset Sync Options
set :db_local_clean, true
set :db_remote_clean, true
set :assets_dir, %w(public/system) # be careful, this is passed to rsync
set :local_assets_dir, "public/" # be careful, this is passed to rsync
set :disallow_pushing, true # safety switch


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

##### RVM Options

set :rvm_type, :system # We are using a "system" level RVM install
set :rvm_autolibs_flag, "read-only"
set :rvm_require_role, :app
#set :rvm_ruby_string, :release_path
set :rvm_ruby_version, -> { "#{fetch(:ruby_version)}@#{fetch(:application)}-#{fetch(:rails_env)}" }

# Since we are using nginx/passenger, rvm, ruby and gemset must match the system
# ... so we are not going to create/install anything here
#before 'deploy:setup', 'rvm:install_rvm'
#before 'deploy:setup', 'rvm:install_ruby'
#before 'deploy:setup', 'rvm:create_gemset'

# This might be nice, for later (TODO)
#require "rvm/capistrano/alias_and_wrapp"
#before 'deploy', 'rvm:create_alias'
#before 'deploy', 'rvm:create_wrappers'

# RVM Bundler Overrides - use gemsets (system)
set :bundle_path, nil
set :bundle_binstubs, nil
set :bundle_flags, '--system --quiet'

##### END RVM Options

## Display GIT Branch
namespace :git do

  desc "Verify git branch"
  task :verify_branch do
    run_locally do
      branch=fetch(:branch)
      repo=fetch(:repo_url)
      if test("git ls-remote #{repo} #{branch} | grep -q #{branch}")
        # branch appears to be remote, but we should verify that it is pushed
      else
        fail("\n\n\nERROR: The branch '#{branch}' is not available at #{repo}.\n\n\n".red)
      end
    end
  end

  desc "Display effective git branch"
  task :display_branch do
    run_locally do
      puts "\n\n\n *** Deploying Git Branch: #{fetch :branch} *** \n\n\n\n".green
    end
  end

  # hacky using rvm:hook
  before 'rvm:hook', 'git:display_branch'
  before :display_branch, :verify_branch

end


namespace :db do

  desc "Drop DB tables then rerun all migrations and seed database"
  task :rebuild do
    on roles(:app) do
      within release_path do
        # Stop application somehow?
        execute :rake, "db:drop RAILS_ENV=#{fetch(:rails_env)}" rescue nil
        execute :rake, "db:create db:migrate db:seed RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end

  desc "migrate db"
  task :migrate do
    on roles(:app) do
      within release_path do
        execute :rake, "db:migrate RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end

  desc "seed db"
  task :seed do
    on roles(:app) do
      within release_path do
        execute :rake, "db:seed RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end

end

namespace :deploy do

  # Simple restart
  desc 'Restart application'
  task :restart do
    on roles(:app, :web), in: :sequence, wait: 5 do
      execute :mkdir, '-p', "#{ release_path }/tmp"
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  #after :restart, :clear_cache do
  #  on roles(:web), in: :groups, limit: 3, wait: 10 do
  #    # Here we can do anything such as:
  #     within release_path do
  #       execute :rake, 'cache:clear'
  #     end
  #  end
  #end

## Custom tasks should be placed in lib/capistrano/tasks

end

# Production Sync Tasks
namespace :prodsync do

  # Sync APP
  desc 'Sync Production App'
  task :app do
    on roles(:app) do
      within current_path do
        execute :cap, 'production', 'app:local:sync', 'SKIP_DATA_SYNC_CONFIRM=true'
      end
    end
  end

  # Sync DB Only
  desc 'Sync Production DB'
  task :db do
    on roles(:app) do
      within current_path do
        execute :cap, 'production', 'db:local:sync', 'SKIP_DATA_SYNC_CONFIRM=true'
      end
    end
  end

  # Sync ASSETS Only
  desc 'Sync Production Assets'
  task :assets do
    on roles(:app) do
      within current_path do
        execute :cap, 'production', 'assets:local:sync', 'SKIP_DATA_SYNC_CONFIRM=true'
      end
    end
  end
end

## END
