


# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }

## Vagrant SSH Stuff

set :ssh_config,  "tmp/.vagrant_ssh_config"
set :vagrant_host, 'app'

set :ssh_options, {
        config:  fetch(:ssh_config),
}


namespace :ssh do

  desc "Generate Vagrant SSH Configuration"
  task :generate_config do
    run_locally do
      ssh_config = fetch(:ssh_config).to_s
      puts "Generating #{ssh_config}"
      execute "mkdir -p $(dirname #{ssh_config})" if ssh_config.include? '/'
      execute "vagrant ssh-config > #{ssh_config}"
    end
  end

  before "rvm:hook", "ssh:generate_config"

  desc "Destroy Vagrant SSH Configuration"
  task :destroy_config do
    run_locally do
      puts "Destroying #{:ssh_config}..."
      execute "/usr/bin/env rm -f #{:ssh_config}"
    end
  end

  desc "Pretty-print Vagrant SSH config."
  task :show_config do
    require 'PP'
    netssh_config = Net::SSH::Config.for(fetch(:vagrant_host), [fetch(:ssh_config)])
    pp netssh_config
  end

  #after :generate_config, :show_config
  before :show_config, :generate_config

end


#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }

server fetch(:vagrant_host),
    roles:  %w{web app}

