# https://www.nasdaq.com/market-activity/stocks/fb/insider-activity
class InsiderTransaction < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :for_ticker, -> ticker { where ticker: ticker.upcase if ticker }
  scope :for_insider, -> insider { where insider_name: insider if insider }
  scope :for_direction, -> direction { direction == 'buy' ? buys : sells }
  scope :buys, -> { where 'shares > 0' }
  scope :sells, -> { where 'shares < 0' }
  scope :with_price, -> { where.not price: nil }
  scope :market_only, -> { where sec_code: %w[P S] }

  def buy? = shares.to_i > 0
  def date_gap = (date && filling_date && filling_date - date).to_i
  def subkey = data['subkey']
  def shares_percent = (shares.to_f / shares_final.to_f if shares_final.to_f != 0)

  class << self
    def import_iex_data(data)
      data.each do |item|
        next if exists? ticker: item['symbol'], insider_name: item['fullName'], date: item['transactionDate']
        puts "Import insider transaction for #{item['symbol']} on #{item['transactionDate']} by #{item['fullName']}"
        create!(
          ticker:        item['symbol'],
          shares:        item['transactionShares'],
          shares_final:  item['postShares'],
          price:         item['transactionPrice'],
          cost:          item['transactionValue'],
          date:          item['transactionDate'],
          filling_date:  item['filingDate'],
          insider_name:  item['fullName'],
          insider_title: item['reportedTitle'],
          sec_code:      item['transactionCode'],
          source:        'iex',
          data:          item,
        )
      rescue ActiveRecord::RangeError => e
        puts "IEX insider transaction import error (#{item&.dig 'symbol'}): #{e}".red
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
      data = ApiCache.get "cache/iex-insider-transactions/#{instrument.ticker} transactions #{Date.current.to_s :number}.json" do
        puts "Load insider transactions for #{instrument.ticker}"
        IexConnector.insider_transactions(instrument.ticker)
      end
      import_iex_data data
    end
  end
end

__END__
InsiderTransaction.import_iex_data_from_dir
InsiderTransaction.import_iex_data_from_remote 'aapl'
InsiderTransaction.import_iex_data_from_file 'cache/iex-insider-transactions/NLOK transactions 20210318.json'
