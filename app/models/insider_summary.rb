class InsiderSummary < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def long? = net && net > 0
  def net_value = net && net * instrument.last

  class << self
    def import(instrument)
      instrument = Instrument[instrument]

      items = ApiCache.get "cache/iex-insider-summaries/#{instrument.ticker} #{Date.current.to_s :number}.json" do
        puts "Load insider summary for #{instrument.ticker}"
        Iex.insider_summary(instrument.iex_ticker)
      end

      items.each do |item|
        date = Date.ms item['date']
        ticker = item['symbol']
        name = item['fullName']
        puts "Import insider summary for #{ticker} on #{date} by #{name}"

        record = find_or_initialize_by ticker: ticker, name: name
        next if record.date && record.date > date

        record.update!(
          net:    item['netTransacted'],
          bought: item['totalBought'],
          sold:   item['totalSold'],
          title:  item['reportedTitle'],
          date:   date,
          source: 'iex',
        )
      end
    end
  end
end

__END__

InsiderSummary.import 'DK'
