# =========================================================================
# Global Settings
# =========================================================================

# Base settings
set :application, 'firefly'

# Stages settings
set :stages,       %w( staging production )
set(:rack_env)     { stage }

require 'capistrano/ext/multistage'

# Repository settings
set :repository,    "git@github.com:ifad/firefly.git"
set :scm,           "git"
set :branch,        fetch(:branch, "master")
set :deploy_via,    :remote_cache
set :deploy_to,     "/home/rails/apps/#{application}"
set :use_sudo,      false

# Account settings
set :user,          fetch(:user, 'firefly')

ssh_options[:forward_agent] = true
ssh_options[:auth_methods]  = %w( publickey )

# =========================================================================
# Dependencies
# =========================================================================
depend :remote, :command, "gem"
depend :remote, :command, "git"

# =========================================================================
# Extensions
# =========================================================================
def compile(template)
  location = fetch(:template_dir, File.expand_path('../deploy', __FILE__)) + "/#{template}"
  config   = ERB.new File.read(location)
  config.result(binding)
end

namespace :deploy do
  desc 'Restarts the application.'
  task :restart, :roles => :app do
    pid = "#{deploy_to}/.unicorn.pid"
    run "test -f #{pid} && kill -USR2 `cat #{pid}` || true"
  end

  namespace :ifad do
    # Harden permisssions up
    on :after, :only => %w( deploy:setup deploy:create_symlink ),
      :except => { :no_release => true } do
      run '/home/rails/bin/setup_permissions'
    end

    desc '[internal] Symlink rbenv version'
    task :symlink_rbenv_version, :except => { :no_release => true } do
      run "ln -s #{deploy_to}/.rbenv-version #{release_path}"
    end
    after 'deploy:update_code', 'deploy:ifad:symlink_rbenv_version'
  end

  # =========================================================================
  # Database tasks
  # =========================================================================
  namespace :db do
    desc '[internal] Creates the database.yml configuration file in shared path.'
    task :setup do
      run "mkdir -p #{shared_path}/{db,config}"
      put compile('database.yml.erb'), "#{shared_path}/config/database.yml"
    end
    after 'deploy:setup', 'deploy:db:setup'


    desc '[internal] Updates the database.yml symlink'
    task :symlink do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    after 'deploy:update_code', 'deploy:db:symlink'
  end

  namespace :config do
    desc '[internal] Creates the firefly.yml configuration file in shared path.'
    task :setup do
      run "mkdir -p #{shared_path}/{firefly,config}"
      put compile('firefly.yml.erb'), "#{shared_path}/config/firefly.yml"
    end
    after 'deploy:setup', 'deploy:config:setup'


    desc '[internal] Updates the firefly.yml symlink'
    task :symlink do
      run "ln -nfs #{shared_path}/config/firefly.yml #{release_path}/config/firefly.yml"
    end
    after 'deploy:update_code', 'deploy:config:symlink'
  end
end

after 'deploy', 'deploy:cleanup'

require 'bundler/capistrano'
set :bundle_flags, "--deployment --quiet --binstubs #{deploy_to}/bin"

#require 'airbrake/capistrano'
