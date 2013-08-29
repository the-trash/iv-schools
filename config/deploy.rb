load "config/capistrano/helpers"

# =========================================================
# Params
# =========================================================
set :site_name,   "iv-schools.ru"
set :server_addr, "zykin-ilya.ru"
set :application, site_name

default_run_options[:shell] = "/bin/bash --login"

# base vars
set :gemset_name,  :iv_schools
set :ruby_version, "ree-1.8.7-2012.02"

set :user,        :open_cook_web
set :socket_name, :iv_schools_server
set :users_home,  "/var/www/open_cook_web/data"
set :deploy_to,   "#{users_home}/www/#{application}"

# helper vars
set :to_app,     "cd #{release_path} "
set :to_current, "cd #{current_path} "

set :app_env,    "RAILS_ENV=production "
set :rvm_src,    'source "$HOME/.rvm/scripts/rvm"'

set :use_ruby,    "rvm use #{ruby_version} "
set :use_gemset,  _join([rvm_src, use_ruby, "rvm gemset use #{gemset_name} "])

# deploy params
set :scm,         :git
set :branch,      :master
set :deploy_via,  :remote_cache
set :repository,  "git@github.com:the-teacher/iv-schools.git"
server server_addr, :app, :web, :db, :primary => true

# connection params
set :use_sudo, false
default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }

# releases cleanup
set :keep_releases, 5
after "deploy:restart", "deploy:cleanup"

# =========================================================
# Tasks
# =========================================================
load "config/capistrano/web_server"
load "config/capistrano/app"

# precompile assets before App reboot
before "deploy:create_symlink", "app:assets_build"

namespace :deploy do
  task :migrate do
    app.db_create
    app.db_migrate
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    app.symlinks
    web_server.restart
  end

  task :db_update do
    deploy.update_code
    deploy.finalize_update
    app.symlinks
    app.bundle
    app.db_migrate
  end
end