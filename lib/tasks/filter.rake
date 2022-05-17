namespace :filter do
  envtask :run do
    CandleCache.preload
    PriceCache.preload
    instruments = Instrument.select(&:down_in_2021?)
    tickers = instruments.map(&:ticker).sort
    puts "Total: #{tickers.count}"
    puts tickers.join(' ')
  end

  envtask :outdated do
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

  envtask :bottom_gainers do
    PriceCache.preload

    falling_since = 3.months.ago
    falling_period = falling_since..Current.date
    low_reached_in = 3.weeks.ago
    low_reach_period = low_reached_in.to_date..Current.date
    gain_range = 0.05..nil
    results = []

    Instrument.find_each do |inst|
      lowest_candle = inst.lowest_body_in falling_period
      next unless lowest_candle.date.in? low_reach_period

      rel_diff = inst.gain_since(lowest_candle.range_low, :last)
      next unless rel_diff.to_f.in? gain_range

      puts "#{inst.ticker.ljust 8} [#{inst.info&.sector_code.to_s.ljust 21}] since #{lowest_candle.date} #{(rel_diff * 100).to_i}% from #{lowest_candle.range_low} / #{lowest_candle.low}"
      results << inst
    end

    puts
    puts "Total: #{results.count}"
    puts results.join(' ')
  end

  envtask :insider_buys do
    results = {}
    Instrument.find_each do |inst|
      discount = 0.7
      min_price = inst.last.to_f * 0.5
      transactions = inst.insider_transactions.buys.market_only.where('price > ?', min_price)
      sum = transactions.map { |tx| tx.cost.to_d }.sum
      next if sum < 500_000
      results[inst.ticker] = sum
    end

    results.sort_by(&:last).each do |ticker, sum|
      puts "#{ticker.ljust 8} #{sum.round.to_s(:delimited).rjust(20)}"
    end

    puts "Total: #{results.count}"
    puts "Tickers: #{results.keys.sort.join(' ')}"
  end

  envtask :ipos do
    excluded = %w[AMR ALTO GOTU GTX INTEQ LQDA LTMAQ MODV PRG TTE VTRS WOLF ZWS CLSK DASB FUBO].to_set
    Instrument.abc.select do |inst|
      next if inst.eur?
      next if excluded.include?(inst.ticker)
      next if inst.ticker.include?('@')
      if oldest = inst.candles.asc.first
        if oldest.date > '2020-07-01'.to_date
          puts inst.ticker
        end
      end
    end
  end
end


__END__

rake filter:run
rake filter:outdated
rake filter:ipos
