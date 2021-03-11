namespace :tinkoff do
  task 'candles:download' => :environment do
    Instrument.tinkoff.abc.each do |inst|
      TinkoffConnector.download_candles inst, interval: 'day'
    end
  end

  task 'candles:import' => :environment do
    TinkoffConnector.import_candles "db/tinkoff-candles-#{Date.today.to_s :number}"
  end
end

__END__
bundle exec rake tinkoff:candles:download
rake tinkoff:candles:import
