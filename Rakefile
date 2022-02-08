# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

$log_tinkoff = ENV['LOG_TINKOFF']

def envtask(task_name, &block)
  deps = :env
  if task_name.is_a?(Hash)
    deps = task_name.values.first
    task_name = task_name.keys.first
  end
  task task_name => deps, &block
end

def rake(*tasks)
  Array(tasks).each { |task| Rake::Task[task].invoke }
end

module R
  module_function

  def tickers_from_env
    ENV['ticker'].presence || ENV['t'].presence || ENV['tickers'].presence
  end

  def instruments_from_env
    tickers = tickers_from_env
    tickers ?
      Instrument.for_tickers(tickers.split(/\s|,/)) :
      ENV['set'] ?
        Instrument.in_set(ENV['set']) :
        nil
  end

  def instruments_from_env!
    instruments_from_env || raise("Please set the 'tickers=' env variable!")
  end

  def confirmed? = true?(:ok)
  def ok? = confirmed?
  def true?(variable) = ENV[variable.to_s] == '1'
  def true_or_nil?(variable) = true?(variable) || ENV[variable.to_s].blank?
  def false?(variable) = ENV[variable.to_s] == '0'
end

Rails.application.load_tasks

task :env => :environment
