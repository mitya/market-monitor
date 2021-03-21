namespace :filter do
  task 'run' => :env do
    Current.preload_day_candles_for Instrument.all
    Current.preload_prices_for Instrument.all
    instruments = Instrument.select(&:down_in_2021?)
    tickers = instruments.map(&:ticker).sort
    puts "Total: #{tickers.count}"
    puts tickers.join(' ')
  end
end


__END__

rake filter:run
