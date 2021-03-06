set :rails_env, 'production'
set :branch, 'production'
set :html_branch, 'production'
set :html_deploy_to, "/caishuo/web/html"


role :app, %w{www-data@139.219.2.81:1011 www-data@139.219.2.81:1012 www-data@139.219.2.81:1013 www-data@139.219.2.81:2021 www-data@139.219.2.81:2042}
role :web, %w{www-data@139.219.2.81:1011 www-data@139.219.2.81:1012 www-data@139.219.2.81:1013} 
role :db,  %w{www-data@139.219.2.81:2021}
role :bg,  %w{www-data@139.219.2.81:2021  www-data@139.219.2.81:2042}
role :sneakers, %w{www-data@139.219.2.81:2042}


role :resque_worker, "www-data@139.219.2.81:2021"
role :resque_scheduler, "www-data@139.219.2.81:2042"


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

#server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# And/or per server (overrides global)
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
