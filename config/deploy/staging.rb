# Staging Specific Deployment Configuration
# ======================

set :bundle_without, %w{production}.join(' ')

#server 'stage.example.com',
#    user: fetch(:application),
#    port: 1022
#    roles: %w{web app db},
#    primary: true
