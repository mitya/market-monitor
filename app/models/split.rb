class Split < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def load_all
      Instrument.iex_sourceable.after('SP').abc.each do |inst|
        puts "Load splits for #{inst.ticker}..."
        splits = Iex.splits(inst.iex_ticker)
        splits.each do |hash|
          puts "Get  split  for #{inst.ticker} on #{hash['exDate']}"
          create_or_find_by! instrument: inst,
            desc: hash['description'],
            ex_date: hash['exDate'],
            declared_date: hash['declaredDate'],
            ratio: hash['ratio'],
            from_factor: hash['fromFactor'],
            to_factor: hash['toFactor']
        end
      end
    end

    def affected_tickers(since: '2021-01-01'.to_date)
      where('ex_date > ?', since).distinct.pluck(:ticker)
    end
  end
end


__END__
Split.load_all
Split.affected_tickers
Candle.where(ticker: Split.affected_tickers).delete_all
DateIndicators.recreate_for_all Split.affected_tickers
