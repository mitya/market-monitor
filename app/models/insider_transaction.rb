# https://www.nasdaq.com/market-activity/stocks/fb/insider-activity
class InsiderTransaction < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :for_ticker, -> ticker { where ticker: ticker.upcase if ticker }
  scope :for_tickers, -> tickers { where ticker: tickers.map(&:upcase) }
  scope :for_insider, -> insider { where insider_name: insider if insider }
  scope :for_direction, -> direction { direction == 'buy' ? buys : sells }
  scope :buys, -> { where 'shares > 0' }
  scope :sells, -> { where 'shares < 0' }
  scope :with_price, -> { where.not price: nil }
  scope :market_only, -> { where sec_code: %w[P S] }
  scope :gurufocus, -> { where source: 'gf' }
  scope :iex, -> { where source: 'iex' }

  def buy? = shares.to_i > 0
  def sell? = !buy?
  def date_gap = (date && filling_date && filling_date - date).to_i
  def subkey = data['subkey']
  # def shares_percent = (shares.to_f / shares_final.to_f * 100 if shares_final.to_f != 0)
  def shares_percent = shares_final.to_f == 0 ? -100 : (buy? && shares_final <= shares) ? 100 : shares.to_f / (shares_final.to_f - shares.to_f) * 100

  def nasdaq_url = "https://www.nasdaq.com/market-activity/stocks/#{ticker.downcase}/insider-activity"

  def directness = data&.dig('directIndirect')
  def exercise_price = data&.dig('conversionOrExercisePrice')

  def full_cost = cost&.nonzero? || (price.to_d * shares.to_i).abs

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

    def import_iex_data_from_remote(instrument, delay: 0)
      instrument = Instrument[instrument]
      data = ApiCache.get "cache/iex-insider-transactions/#{instrument.ticker} transactions #{Date.current.to_s :number}.json" do
        puts "Load insider transactions for #{instrument.ticker}"
        Iex.insider_transactions(instrument.ticker)
      end
      import_iex_data data
    end

    def parse_guru_focus
      get_row_field = -> (row, field, extra = nil) { row.css("td[data-column='#{field}']#{extra}").first&.inner_text&.strip }

      Pathname.glob(Rails.root / "tmp/gurufocus/2021-07*.html").each do |file|
        doc = Nokogiri::HTML(file)
        table = doc.css('table').first
        table.css('tr').each do |row|
          ticker = row.css("td[data-column='Ticker']").first&.inner_text&.strip
          if ticker && Instrument.get(ticker)&.usd?
            insider_name  = get_row_field.call row, 'Insider Name'
            insider_title = get_row_field.call row, 'Insider Position'
            date          = get_row_field.call row, 'Date'
            buy_sell      = get_row_field.call row, 'Buy/Sell'
            shares_number = get_row_field.call row, 'Insider Trading Shares'
            shares_final  = get_row_field.call row, 'Final Share'
            price         = row.css("td[data-column='Price']").last&.inner_text&.strip
            cost          = get_row_field.call row, 'Cost(000)'

            date = Date.parse(date)
            is_sell = buy_sell == 'Sell'
            shares_number = shares_number.delete(',').to_i
            shares_number = -shares_number if is_sell
            shares_final = shares_final.delete(',').to_i
            price = price.delete('$,').to_d
            cost = (cost.delete('$,').to_d * 1000).nonzero?

            record = find_or_initialize_by(
              ticker:        ticker,
              shares:        shares_number,
              price:         price,
              insider_name:  insider_name,
              date:          date,
            )

            next if record.persisted?

            puts "Import GF insider transaction: #{date} #{buy_sell.ljust 4} #{ticker.ljust 8} by #{insider_name} #{shares_number} @ #{price}"
            record.update!(
              shares_final:  shares_final,
              cost:          cost,
              filling_date:  nil,
              insider_title: insider_title,
              sec_code:      is_sell ? 'S' : 'P',
              source:        'gf',
            )
          end
        end
      end
    end

    def remove_dups
      results = 0
      where(source: 'gf').find_each do |tx|
        count = where(source: 'gf', ticker: tx.ticker, date: tx.date, price: tx.price, insider_name: tx.insider_name, shares: tx.shares).count
        results += 1 if count > 1
      end
      puts results
    end
  end
end

__END__
InsiderTransaction.import_iex_data_from_dir
InsiderTransaction.import_iex_data_from_remote 'aapl'
InsiderTransaction.import_iex_data_from_file 'cache/iex-insider-transactions/NLOK transactions 20210318.json'
InsiderTransaction.parse_guru_focus
InsiderTransaction.remove_dups
