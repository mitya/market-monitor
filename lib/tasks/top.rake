envtask :main do
  rake 'iex:days:previous'
  rake 'tinkoff:days:latest'
  if Current.us_market_open?
    rake 'iex:prices'          unless R.false?(:price)
    rake 'iex:days:today'      unless R.false?(:today)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
  else
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices'      unless R.false?(:price)
  end
  rake 'aggregate'
end

task :prices => %w[iex:prices tinkoff:prices:uniq]

envtask :aggregate do
  Aggregate.create_for_all
end
