envtask :day do
  rake 'iex:candles:days:previous'
  rake 'tinkoff:candles:day:latest'
  if Current.us_market_open?
    rake 'iex:prices:all'         unless R.false?(:price)
    rake 'iex:candles:days:today' unless R.false?(:today)
    rake 'tinkoff:prices:uniq'    unless R.false?(:price)
  else
    rake 'tinkoff:prices:all'     unless R.false?(:price)
  end
end

envtask :aggregate do
  Aggregate.create_for_all
end
