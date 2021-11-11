require 'csv'

class RefreshPricesFromIex
  include StaticService

  def refresh
    csv = Iex.tops_csv.body
    Pathname("cache/iex/tops.csv").write(csv)
    Price.transaction do
      CSV.parse(csv, headers: true).each { |row| process_result row }
      Price.set_missing_prices_to_close
    end
    nil
  end

  def refresh_json(symbols = [])
    prices = ApiCache.get "cache/iex/tops.json", skip_if: symbols.any?, ttl: 15.minutes do
      puts "Load new prices from IEX..."
      Iex.tops(*symbols)
    end
    Price.transaction do
      prices.sort_by { |p| p['symbol'] }.each { |result| process_result result }
      Price.set_missing_prices_to_close
    end
    nil
  end

  def refresh_premium
    refresh_json Instrument.premium.map(&:iex_ticker)
  end

  alias call refresh

  private

  def process_result(result)
    instrument = instruments_index[result['symbol']]
    return unless instrument
    return unless instrument.usd?

    price = result['lastSalePrice']
    last_at = Time.ms(result['lastUpdated'].to_i)
    return if instrument.price!.last_at && instrument.price.last_at > last_at
    return if price.to_f == 0

    instrument.price.update! value: price, last_at: last_at, source: 'iex', low: nil, volume: nil
  end

  def instruments_index
    @instruments_index ||= Instrument.includes(:price, :info).index_by(&:iex_ticker)
  end
end

__END__
