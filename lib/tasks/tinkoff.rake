namespace :tinkoff do
  task 'candles:download' => :environment do
    Instrument.tinkoff.abc.each do |inst|
      TinkoffConnector.download_day_candles_upto_today inst
    end
  end

  task 'candles:download:current' => :environment do
    Instrument.tinkoff.abc.each do |inst|
      TinkoffConnector.download_day_candle_for_today inst
    end
  end

  task 'candles:import' => :environment do
    TinkoffConnector.import_candles "db/tinkoff-day-#{Date.today.to_s :number}"
  end

  task 'candles:import:current' => :environment do
    TinkoffConnector.import_candles "db/tinkoff-day-#{Date.today.to_s :number}-current"
  end

  task 'prices:refresh' => :environment do
    InstrumentPrice.refresh
  end
end

__END__
rake tinkoff:candles:download
rake tinkoff:candles:download:current
rake tinkoff:candles:import
rake tinkoff:candles:import:current
