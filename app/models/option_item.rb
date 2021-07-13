class OptionItem < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def load_all(tickers)
      tickers.each { |ticker| load_soonest ticker }
    end

    def load_soonest(ticker)
      return if ticker < 'COTY'
      instrument = Instrument.get(ticker)
      max_strike = instrument.recent_high * 1.5
      min_strike = instrument.recent_low * 0.65
      strike_range = min_strike .. max_strike

      soonest_dates = OptionItemSpec.where(ticker: ticker).where('date >= ?', Current.date).order(:date).distinct.pluck(:date).first(3)
      soonest_options = OptionItemSpec.where(ticker: ticker).where(date: soonest_dates, strike: strike_range).order(:ticker, :side, :date, :strike)
      soonest_options.each do |option|
        puts "Load IEX option data for #{option.code}..."
        strikes = Iex.options_chart(option.code, range: '1w')
        strikes.each do |strike|
          update_date = strike['lastUpdated']
          volume = strike['volume']
          open_interest = strike['openInterest']

          record = find_or_initialize_by ticker: ticker, code: option.code, updated_on: update_date
          next if record.persisted?
          puts "Set option data for #{ticker.ljust(5)} #{option.code} on #{update_date} #{volume.to_s.rjust 6} #{open_interest.to_s.rjust 6}".send(record.new_record?? :green : :yellow)

          record.update! side: option.side, strike: option.strike,
            volume:        volume,
            open_interest: open_interest,
            date:          strike['expirationDate'],
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
