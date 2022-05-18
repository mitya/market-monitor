class PriceTarget < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', optional: true

  scope :current, -> { where current: true }

  %w[low average high].each do |method|
    define_method("#{method}_in_usd") { CurrencyConverter.convert send(method), currency, 'USD'  }
  end

  class << self
    def import_iex_data(ticker, item)
      target = find_or_initialize_by ticker: ticker, date: item['updatedDate']
      puts "Import price target for #{ticker} on #{target.date}" if target.new_record?
      target.high           = item['priceTargetHigh']
      target.low            = item['priceTargetLow']
      target.average        = item['priceTargetAverage']
      target.currency       = item['currency']
      target.analysts_count = item['numberOfAnalysts']
      target.source         = 'iex'
      target.save!
    end

    def import_iex_data_from_remote(instrument, delay: 0)
      instrument = Instrument[instrument]

      return if ApiCache.exist? "cache/iex-price-targets/#{instrument.ticker} targets #{Date.current.to_s :number}.json"
      data = ApiCache.get "cache/iex-price-targets/#{instrument.ticker} targets #{Date.current.to_s :number}.json" do
        puts "Load   price target for #{instrument.ticker}"
        Iex.price_target(instrument.iex_ticker)
      end

      import_iex_data instrument.ticker, data
      set_current_for instrument.ticker
      sleep delay

    rescue RestClient::NotFound => e
      puts "Load   price target for #{instrument.ticker} failed with #{e}".red
    end

    def set_current_for(ticker)
      *old, last = where(ticker: ticker).order(:date)
      puts "Missing price target record for #{ticker}".red if !last
      last&.update! current: true
      old.each { |target| target.update! current: nil }
    end

    def set_current
      group(:ticker).pluck(:ticker).sort.each { |ticker| set_current_for ticker }
    end

    def outdated(threshold: Current.date.beginning_of_year)
      Instrument.usd.iex.abc.select { |inst| inst.price_targets.where('date > ?', threshold).none? }
    end
  end
end

__END__
PriceTarget.import_iex_data_from_remote 'aapl'
PriceTarget.set_current
PriceTarget.outdated.map(&:ticker).sort
