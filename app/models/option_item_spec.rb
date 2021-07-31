class OptionItemSpec < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def load_all(tickers)
      tickers.each do |ticker|
        load(ticker)
      end
    end

    def load(ticker)
      ApiCache.get "cache/iex-options/#{ticker} #{Date.current.to_s :number}.json" do
        puts "Load options specs for #{ticker}"
        Iex.options_specs(ticker)
      end
    end

    def load_all_dates
      ApiCache.get "cache/iex-options/all #{Date.current.to_s :number}.json" do
        puts "Load all options dates"
        Iex.options_dates
      end
    end

    def create_all(tickers)
      tickers.each do |ticker|
        instrument = Instrument.get_by_iex_ticker(ticker)
        # next if exists?(ticker: instrument.ticker)
        data = load(ticker)
        data.each do |spec|
          find_or_create_by! code: spec['symbol'] do |record|
            puts "Create option spec for #{ticker} #{spec['expirationDate']}: #{record.code}"
            record.assign_attributes(
              ticker: instrument.ticker,
              date:   spec['expirationDate'],
              side:   spec['side'],
              strike: spec['strike']
            )
          end
        end
      end
    end
  end
end

__END__

OptionItemSpec.create_all
