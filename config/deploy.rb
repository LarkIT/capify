# config valid only for current version of Capistrano
lock '3.4.0'

# GIT Repo URL
set :repo_url, "git@github.com:ORGANIZATION/REPOSITORY.git"

# Ruby Version (used for RVM) - MUST MATCH PASSENGER/SERVER CONFIG!
set :ruby_version, '2.2.0'

# Application name (default to using "railsapp")
#   -- determines deploy path and user
set :application, 'railsapp'

### NO FURTHER CUSTOMIZATIONS SHOULD BE NECESSARY
#

def colorize(text, color_code)
          "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end

# Determine Rails Environment
cap_stage = fetch(:stage).to_s
if cap_stage.include? 'production' or cap_stage.include? 'staging'
  set :rails_env, fetch(:stage)
else
  set :rails_env, 'development'
end

# Other Rails Settings
set :migration_role, :app
set :conditionally_migrate, true
set :assets_roles, [:web, :app]
set :normalize_asset_timestamps, false

# Default branch is :master
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, ->{ "/web/#{fetch(:application)}/#{fetch(:rails_env)}" }

# Default value for :scm is :git
set :scm, :git
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

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

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

## Global SSH Options
set :ssh_options, {
  forward_agent: true,
  port: 22222,
  keepalive: true,
  keepalive_interval: 60, #seconds - prevents idle timeouts on long tasks
}

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
        fail(red("ERROR: The branch '#{branch}' is not available at #{repo}."))
      end
    end
  end

  desc "Display effective git branch"
  task :display_branch do
    run_locally do
      puts green("\n\n\n *** Deploying Git Branch: #{fetch :branch} *** \n\n\n\n")
      #ssh_config = fetch(:ssh_config).to_s
      #puts "Generating #{ssh_config}"
      #execute "mkdir -p $(dirname #{ssh_config})" if ssh_config.include? '/'
      #execute "vagrant ssh-config > #{ssh_config}"
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
        execute :rake, "db:drop RAILS_ENV=#{fetch(:rails_env)}" rescue nil
        execute :rake, "db:create db:migrate db:seed RAILS_ENV=#{fetch(:rails_env)}"
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

end
