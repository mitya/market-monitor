class PublicSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :sa, -> { where source: 'SA' }

  after_save :load_price_if_missing

  def load_price_if_missing
    return if price
    Iex.import_day_candles instrument, date: MarketCalendar.closest_weekday(date)
    update! price: instrument.price_on_or_before(date)&.close
  end

  def effective_price
    price.presence || instrument.day_candles.find_date_or_before(date)&.close
  end

  class << self
    def load
      Pathname("db/signals.txt").readlines(chomp: true).each do |line|
        next if line.blank?
        date, source, ticker, price, score = line.split
        price = nil if price.to_s.downcase == '-'
        next puts "Missing #{ticker} for #{source}".red unless Instrument.get(ticker)
        next if exists? ticker: ticker, source: source, date: date
        create! ticker: ticker, source: source, date: date, price: price, score: score
      end
    end

    def parse_seeking_alpha
      get_all_by_test_id = -> (element, field) { element.css("[data-test-id=#{field}]") }
      get_text_by_test_id = -> (element, field) { get_all_by_test_id.(element, field)&.first&.inner_text&.strip }

      Pathname.glob(Rails.root / "tmp/seekingalpha/*.txt").each do |file|
        ticker = file.basename('.txt')
        next if file.size < 100
        doc = Nokogiri::HTML(file)

        # get_all_by_test_id.(doc, 'post-list-item').each do |item|
        doc.css('[data-test-id=post-list]').first.css('[data-test-id=post-list-item]').each do |item|

          title = get_text_by_test_id.(item, 'post-list-item-title')
          date = get_text_by_test_id.(item, 'post-list-date')
          comments_count = get_text_by_test_id.(item, 'post-list-comments')
          author = get_text_by_test_id.(item, 'post-list-author')
          score = get_text_by_test_id.(item, 'quant-badge')

          score = convert_sa_rating(score)
          date = date.include?('Yesterday') ? Current.us_date.yesterday :
                 date.include?('Today') ? Current.us_date :
                 Date.parse(date)
          next unless score

          instrument = Instrument.get(ticker)
          record = find_or_initialize_by ticker: ticker.to_s, source: 'SA', date: date, score: score, post_title: title

          puts "Import SA article on #{date} [#{score}] for #{ticker}: #{title}" if record.new_record?
          record.update! post_author: author, post_comments_count: comments_count, price: instrument.price_on_or_before(date)&.close
        end
      end
    end

    def convert_sa_rating(rating_string)
      SA_RATINGS[rating_string]
    end

    def load_missing_sa_prices
      where(price: nil).find_each &:load_price_if_missing
    end

    def create_sa_stubs(tickers)
      tickers.each do |ticker|
        file = Rails.root / "tmp/seekingalpha/#{ticker}.txt"
        next if file.exist?
        file.write('')
      end
    end
  end

  SA_RATINGS = {
    'Very Bullish' => 5,
    'Bullish' => 4,
    'Neutral' => 3,
    'Bearish' => 2,
    'Very Bearish' => 1,
  }
  SA_RATINGS_INV = SA_RATINGS.invert
end


__END__
PublicSignal.load
PublicSignal.parse_seeking_alpha
PublicSignal.load_missing_sa_prices
PublicSignal.create_sa_stubs ''.split
