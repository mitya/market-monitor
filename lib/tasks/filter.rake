namespace :filter do
  task 'run' => :env do
    Current.preload_day_candles_for Instrument.all
    Current.preload_prices_for Instrument.all
    tickers = Instrument.select { |inst| inst.y2021_open_rel.to_f < 0 }.map(&:ticker).sort
    puts "Total: #{tickers.count}"
    puts tickers.join(' ')
  end
end


__END__

rake filter:run
