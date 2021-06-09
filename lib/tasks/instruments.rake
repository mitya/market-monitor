namespace :instruments do
  envtask :remove do
    Instrument[ENV['ticker']].destroy!
  end

  envtask :check_dead do
    Tinkoff::BadTickers.each do |ticker|
      inst = Instrument.get(ticker)
      if inst
        puts "#{inst} #{inst.candles.day.order(:date).last&.date}"
      end
    end
  end

  envtask :remove_all_dead do
    Tinkoff::BadTickers.each do |ticker|
      Instrument.get(ticker)&.destroy
    end
  end

  envtask(:LoadMissingIexCandles) { LoadMissingIexCandles.call }
  envtask(:ReplaceTinkoffCandlesWithIex) { ReplaceTinkoffCandlesWithIex.call }
end


__END__

Tinkoff::OutdatedTickers.each { |ticker| Instrument.get(ticker)&.destroy }
