class PriceTarget < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def import_iex_data(item)
      puts "Import price target for #{item['symbol']} on #{item['updatedDate']}"
      target = find_or_initialize_by ticker: item['symbol'], date: item['updatedDate']
      target.high           = item['priceTargetHigh']
      target.low            = item['priceTargetLow']
      target.average        = item['priceTargetAverage']
      target.currency       = item['currency']
      target.analysts_count = item['numberOfAnalysts']
      target.source         = 'iex'
      target.save!
    end

    def import_iex_data_from_dir(dir: Pathname("cache/iex-price-targets"))
      Pathname(dir).glob('*.json') { |file| import_iex_data_from_file file }
    end

    def import_iex_data_from_file(file_name)
      import_iex_data JSON.parse File.read file_name
    end

    def import_iex_data_from_remote(instrument, delay: 0)
      instrument = Instrument[instrument]

      return if ApiCache.exist? "cache/iex-price-targets/#{instrument.ticker} targets #{Date.current.to_s :number}.json"
      data = ApiCache.get "cache/iex-price-targets/#{instrument.ticker} targets #{Date.current.to_s :number}.json" do
        puts "Load   price target for #{instrument.ticker}"
        IexConnector.price_target(instrument.ticker)
      end

      import_iex_data data
      sleep delay
      
    rescue RestClient::NotFound => e
      puts "Price target load failed for #{instrument} with #{e}".red
    end
  end
end

__END__
PriceTarget.import_iex_data_from_remote 'aapl'
