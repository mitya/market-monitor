envtask :main do
  rake 'iex:days:previous'
  rake 'tinkoff:days:previous'
  if Current.weekend?
    rake 'iex:prices'          unless R.false?(:price)
    # rake 'iex:days:today'      unless R.false?(:today)
  elsif Current.us_market_open?
    rake 'iex:prices'          unless R.false?(:price)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
  elsif Current.uk_market_open?
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
    # rake 'iex:days:today'          if R.true?(:today)
  else
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices:uniq'      unless R.false?(:price)
  end
  rake 'aggregate'
  rake 'analyze'
  rake 'tinkoff:portfolio:sync'
end

task :prices => %w[iex:prices tinkoff:prices:uniq]

envtask :aggregate do
  Aggregate.create_for_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.date
end

envtask 'aggregate:stats' do
  pp Aggregate.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
  pp PriceSignal.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
end

envtask :analyze do
  PriceSignal.analyze_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.last_closed_day
end

task :a => %w[aggregate analyze]

envtask(:levels) { PriceLevel.search_all }
envtask(:hits) { PriceLevelHit.analyze_all }
envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) {
  PublicSignal.parse_seeking_alpha
  InsiderAggregate.aggregate
}


envtask(:clear_list) do
  puts ENV['tickers'].split(',').map{ |tk| tk.split(':').last }.sort.join("\n")
end
