# config valid only for Capistrano 3.1


lock '3.1.0'

set :application, 'rasbot'
set :repo_url, 'https://github.com/RasPlex/rasbot.git'
set :deploy_to, "/u/apps/#{fetch :application}"

if ENV.has_key? "REVISION" or ENV.has_key? "BRANCH_NAME"
  set :branch, ENV["REVISION"] || ENV["BRANCH_NAME"]
end

set :linked_dirs, %w{node_modules}


namespace :deploy do

  desc 'Install node packages'
  task :install_packages do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        execute :npm, 'install'
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sv, "restart #{fetch :application}"
    end
  end

  after :updating, :install_packages
  after :publishing, :restart
end

