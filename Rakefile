# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

def envtask(task_name, &block)
  task task_name => :env, &block
end

module R
  module_function

  def instruments_from_env
    ENV['set'] ? Instrument.in_set(ENV['set']) :
    ENV['tickers'] ? Instrument.for_tickers(ENV['tickers'].split(/\s|,/)) :
    nil
  end

  def confirmed?
    true? :ok
  end

  def true?(variable)
    ENV[variable.to_s] == '1'
  end
end

Rails.application.load_tasks

task :env => :environment
