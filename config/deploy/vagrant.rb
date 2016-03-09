# Vagrant Specific Deployment Configuration
# ======================

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


server fetch(:vagrant_host),
    roles:  %w{web app}

