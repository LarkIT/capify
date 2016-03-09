### Integration Specific Deployment Settings
# ======================

set :bundle_without, %w{production}.join(' ')

#server 'integ.example.com',
#    user: fetch(:application),
#    port: 1022,
#    roles: %w{web app},
#    primary: true
