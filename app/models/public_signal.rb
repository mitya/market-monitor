class PublicSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def load
      Pathname("db/signals.txt").readlines(chomp: true).each do |line|
        next if line.blank?
        date, source, ticker, price = line.split
        next puts "Missing #{ticker} for #{source}".red unless Instrument.get(ticker)
        find_or_create_by! ticker: ticker, source: source, date: date, price: price
      end
    end
  end
end


__END__
PublicSignal.load
