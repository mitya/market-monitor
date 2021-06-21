namespace :m1 do
  envtask :load do
    tickers = %w[DK FANG CLF X MAC M HRTX ATRA]
    tickers = %w[DK FANG CLF]
    period = '2021-06-01'.to_date .. Current.yesterday

    tickers.each do |ticker|
      MarketCalendar.open_days(period).each { |date| Iex.import_intraday_candles(ticker, date) }
    end
  end
end
