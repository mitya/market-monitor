class InstitutionHolding < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def import(instrument)
      instrument = Instrument[instrument]

      items = ApiCache.get "cache/iex-institutions/#{instrument.ticker} #{Date.current}.json" do
        puts "Load institution holdings for #{instrument.ticker}"
        Iex.institutional_ownership(instrument.iex_ticker)
      end

      items.each do |item|
        ticker = item['symbol']
        date = item['filingDate'].to_date rescue Date.ms(item['date'])
        holder = item['entityProperName']
        puts "Import institution position for #{ticker} on #{date} by #{holder}"

        record = find_or_initialize_by instrument: instrument, holder: holder, date: date

        record.update!(
          shares:    item['adjHolding'],
          shares_na: item['reportedHolding'],
          value:     item['adjMv'],
          reported_on: Date.ms(item['date'])
        )
      end
    end
  end
end

__END__

InstitutionHolding.import 'DK'
