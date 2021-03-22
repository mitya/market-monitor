# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

def envtask(task_name, &block)
  task task_name => :env, &block
end

Rails.application.load_tasks

task :env => :environment
