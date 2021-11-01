namespace :t do
  envtask :check_dead do
    Tinkoff::BadTickers.each do |ticker|
      inst = Instrument.get(ticker)
      if inst
        puts "#{inst} #{inst.candles.day.order(:date).last&.date}"
      end
    end
  end

  envtask :destroy do
    ENV['ticker'].to_s.split.each do |ticker|
      puts "Destroy #{ticker}"
      Instrument[ticker].destroy! if ENV['ok']
    end
  end

  envtask :destroy_all_dead do
    Tinkoff::BadTickers.each do |ticker|
      Instrument.get(ticker)&.destroy
    end
  end
end
