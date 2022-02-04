task :process do
  rake 'aggregate'
  rake 'indicators'
  rake 'analyze'
  rake 'spikes'
  rake 'levels:hits'
  rake 'tinkoff:portfolio:sync'
  rake 'tinkoff:instruments:sync'
end

envtask :aggregate do
  Aggregate.delete_all
  Aggregate.create_for_all date: ENV['date'].presence&.to_date || Current.yesterday
  Aggregate.set_current
end

envtask :aggregate_old do
  MarketCalendar.open_days(Date.current.beginning_of_year, Current.yesterday).each do |date|
    Aggregate.create_for_all date: date, force: false
  end
end

envtask 'aggregate:stats' do
  pp Aggregate.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
  pp PriceSignal.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
end

envtask :indicators do
  DateIndicators.create_for_all
  DateIndicators.set_current
end

envtask :analyze do
  PriceSignal.analyze_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.last_closed_day
end

envtask :analyze_intraday do
  PriceSignal.analyze_intraday_history(%w[EQT], MarketCalendar.open_days(5.days.ago))
end

envtask :analyze_old do
  MarketCalendar.open_days(Date.current.beginning_of_year, '2021-04-16'.to_date).each do |date|
    PriceSignal.analyze_all date: date, force: false
  end
end