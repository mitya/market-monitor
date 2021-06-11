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
envtask('levels:manual') { PriceLevel.load_manual }
envtask('levels:hits') { PriceLevelHit.analyze_all }
envtask('levels:alerts') { PriceLevelHit.analyze_manual }
envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) {
  PublicSignal.parse_seeking_alpha
  InsiderAggregate.aggregate
}


envtask('list:clear') do
  puts ENV['tickers'].split(',').map{ |tk| tk.split(':').last }.sort.join("\n")
end

envtask('list:import') do
  list = ENV['list']
  file = Pathname("db/instrument-sets/#{list}.txt")
  text = file.read
  text = text.gsub(',', "\n")
  tickers = text.each_line.map { |line| line.to_s.split(':').last.upcase.chomp.presence }.uniq.compact
  file.write(tickers.join("\n"))
end
