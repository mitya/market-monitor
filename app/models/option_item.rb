class OptionItem < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def load_all
      OptionItemSpec::TICKERS.each { |ticker| load_soonest ticker }
    end

    def load_soonest(ticker)
      instrument = Instrument.get(ticker)
      max_strike = instrument.recent_high * 1.5
      min_strike = instrument.recent_low * 0.65
      strike_range = min_strike .. max_strike

      soonest_dates = OptionItemSpec.where(ticker: ticker).where('date >= ?', Current.date).order(:date).distinct.pluck(:date).first(3)
      soonest_options = OptionItemSpec.where(ticker: ticker).where(date: soonest_dates, strike: strike_range).order(:ticker, :side, :date, :strike)
      soonest_options.each do |option|
        strikes = Iex.options_chart(option.code, range: '1w')
        strikes.each do |strike|
          update_date = strike['lastUpdated']
          record = find_or_initialize_by ticker: ticker, code: option.code, updated_on: update_date
          record.update! side: option.side, strike: option.strike,
            date:          strike['expirationDate'],
            open_interest: strike['openInterest'],
            volume:        strike['volume'],
            close:         strike['close'],
            open:          strike['open']
        end

      end
    end

  end

end

__END__

OptionItem.load_all
OptionItem.load_soonest 'FCX'
