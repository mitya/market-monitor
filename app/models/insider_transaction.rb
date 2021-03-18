# https://www.nasdaq.com/market-activity/stocks/fb/insider-activity
class InsiderTransaction < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def import_iex_data(data)
      data.each do |item|
        next if exists? ticker: item['symbol'], insider_name: item['fullName'], date: item['transactionDate']
        create!(
          ticker:        item['symbol'],
          shares:        item['transactionShares'],
          shares_final:  item['postShares'],
          price:         item['transactionPrice'],
          value:         item['transactionValue'],
          date:          item['transactionDate'],
          filling_date:  item['filingDate'],
          insider_name:  item['fullName'],
          insider_title: item['reportedTitle'],
          source:        'iex',
          data:          item,
        )
      end
    end

    def import_iex_data_from_dir(dir: Pathname("cache/iex-insider-transactions"))
      Pathname(dir).glob('*.json') { |file| import_iex_data_from_file file }
    end

    def import_iex_data_from_file(file_name)
      import_iex_data JSON.parse File.read file_name
    end

    def import_iex_data_from_remote(instrument)
      instrument = Instrument[instrument]
      data = IexConnector.insider_transactions(instrument.ticker)
      File.write "cache/iex-insider-transactions/#{instrument.ticker} transactions #{Date.current.to_s :number}.json", data.to_json
      import_iex_data data
    end
  end
end

__END__
InsiderTransaction.import_iex_data_from_dir
InsiderTransaction.import_iex_data_from_remote 'aapl'
InsiderTransaction.import_iex_data_from_file 'cache/iex-insider-transactions/AAPL transactions 20210318.json'
Instrument.in_set(:main).each { |inst| InsiderTransaction.import_iex_data_from_remote inst }
