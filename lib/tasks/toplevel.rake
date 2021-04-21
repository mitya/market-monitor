envtask :main do
  rake 'iex:days:previous'
  rake 'tinkoff:days:previous'
  if Current.weekend?
    rake 'iex:prices'          unless R.false?(:price)
    rake 'iex:days:today'      unless R.false?(:today)
  elsif Current.us_market_open?
    rake 'iex:prices'          unless R.false?(:price)
    # rake 'iex:days:today'          if R.true?(:today)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
  else
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices'      unless R.false?(:price)
  end
  rake 'aggregate'
  rake 'analyze'
end

task :prices => %w[iex:prices tinkoff:prices:uniq]

envtask :aggregate do
  Aggregate.create_for_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.date
end

envtask :analyze do
  PriceSignal.analyze_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.yesterday
end
