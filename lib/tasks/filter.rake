namespace :filter do
  task 'run' => :env do
    Current.preload_day_candles_for Instrument.all
    Current.preload_prices_for Instrument.all
    instruments = Instrument.select(&:down_in_2021?)
    tickers = instruments.map(&:ticker).sort
    puts "Total: #{tickers.count}"
    puts tickers.join(' ')
  end

  task 'outdated' => :env do
    ticker_max_dates = Candle.day.group(:ticker).maximum(:date)
    old_tickers_map = ticker_max_dates.select { |ticker, date| date < 1.month.ago }
    old_tickers_map.sort_by(&:second).each { |ticker, date| puts "#{date}: #{ticker}" }
    old_tickers = old_tickers_map.keys
    puts
    puts "Total #{old_tickers.count} outdated tickers"
    puts old_tickers.join(' ')

    tickers_with_too_little_candles = Instrument.left_joins(:candles).group(:ticker).count.select { |ticker, count| count.to_i < 20 }
    tickers_with_too_little_candles.sort_by { |t, c| c.to_i }.each { |ticker, count| puts "#{ticker.ljust 8} - #{count}" }

    if ENV['ok'] == '1'
      Instrument.where(ticker: old_tickers).destroy_all
    end
  end
end


__END__

rake filter:run
rake filter:outdated
