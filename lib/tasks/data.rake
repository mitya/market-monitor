namespace :tinkoff do
  task 'candles:download' => :environment do
    Instrument.tinkoff.abc.each do |inst|
      TinkoffConnector.download_candles inst, interval: 'day', since: Date.new(2021, 1, 1), till: Date.tomorrow
      sleep 0.5
    end
  end

  task 'candles:import' => :environment do
    TinkoffConnector.import_candles "db/tinkoff-candles-2020-full"
  end
end

__END__
rake tinkoff:candles:download
rake tinkoff:candles:import
