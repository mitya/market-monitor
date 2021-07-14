class OptionItem < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def call? = side == 'call'
  def put?  = side == 'put'

  def in_the_money?
    if last = instrument.last
      call? ? last > strike : last < strike
    end
  end

  class << self
    def import_all(tickers, range: '1w')
      tickers.each { |ticker| import ticker, range: range }
    end

    def import(ticker, range: '1w')
      instrument = Instrument.get_by_iex_ticker(ticker)
      max_strike = instrument.recent_high * 1.5
      min_strike = instrument.recent_low * 0.65
      strike_range = min_strike .. max_strike

      soonest_dates = OptionItemSpec.where(ticker: ticker).where('date >= ?', Current.date).order(:date).distinct.pluck(:date).first(3)
      soonest_options = OptionItemSpec.where(ticker: ticker).where(date: soonest_dates, strike: strike_range).order(:ticker, :side, :date, :strike)
      soonest_options.each do |option|
        puts "Load IEX option data for #{option.code}..."
        strikes = Iex.options_chart(option.code, range: range)
        strikes.each do |strike|
          update_date = strike['lastUpdated']
          volume = strike['volume']
          open_interest = strike['openInterest']

          record = find_or_initialize_by ticker: instrument.ticker, code: option.code, updated_on: update_date
          next if record.persisted?
          puts "Set option data for #{ticker.ljust(5)} #{update_date} #{option.side.ljust(4)} #{option.strike} #{volume.to_s.rjust 6} #{open_interest.to_s.rjust 6}".send(record.new_record?? :green : :yellow)

          record.update! side: option.side, strike: option.strike,
            volume:        volume,
            open_interest: open_interest,
            date:          strike['expirationDate'],
            close:         strike['close'],
            open:          strike['open']
        end
      end
    end

    def latest_for_date(ticker, date)
      options = where(ticker: ticker.upcase).where(date: date)
      options.map(&:strike).uniq.sort.flat_map do |strike|
        [
          options.select { |o| o.strike == strike && o.call? }.max_by(&:updated_on),
          options.select { |o| o.strike == strike && o.put? }.max_by(&:updated_on)
        ]
      end.compact
    end

  end

end

__END__

OptionItem.load_all
OptionItem.load_soonest 'FCX'
