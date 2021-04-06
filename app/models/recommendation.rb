class Recommendation < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', optional: true

  scope :current, -> { where current: true }
  scope :for_ticker, -> ticker { where ticker: ticker.upcase if ticker }
  scope :for_tickers, -> tickers { where ticker: tickers.map(&:upcase) }

  CacheDir = Pathname("cache/iex-recommendations")

  alias_attribute :date, :starts_on

  def ratings       = @ratings ||= [buy, overweight, hold, underweight, sell].map(&:to_i)
  def total_ratings = @total_ratings ||= ratings.sum

  %w[buy overweight hold underweight sell none].each do |rating|
    define_method("#{rating}_ratio") { send(rating).to_f / total_ratings }
    define_method("#{rating}_percentage") { (send("#{rating}_ratio") * 100).to_i }
  end

  class << self
    def import_iex_data(ticker, data)
      data.each do |item|
        start_date = Date.ms item['consensusStartDate']
        end_date   = Date.ms item['consensusEndDate']
        recommendation = find_or_initialize_by ticker: ticker, starts_on: start_date, ends_on: end_date
        return if recommendation.persisted?

        puts "Import recommendation for #{ticker} on #{start_date}"
        recommendation.buy                   = item['ratingBuy']
        recommendation.overweight            = item['ratingOverweight']
        recommendation.hold                  = item['ratingHold']
        recommendation.underweight           = item['ratingUnderweight']
        recommendation.sell                  = item['ratingSell']
        recommendation.none                  = item['ratingNone']
        recommendation.scale                 = item['ratingScaleMark']&.round(3)
        recommendation.scale15               = item['ratingScaleMarkOneToFive']&.round(3)
        recommendation.corporate_action_date = Date.ms item['corporateActionsAppliedDate']
        recommendation.save!
      end
    end

    # def import_iex_data_from_dir(dir: CacheDir)
    #   Pathname(dir).glob('*.json') { |file| import_iex_data_from_file file }
    # end
    #
    # def import_iex_data_from_file(file_name)
    #   import_iex_data JSON.parse File.read file_name
    # end

    def import_iex_data_from_remote(instrument, delay: 0)
      instrument = Instrument.get!(instrument)

      # return if ApiCache.exist? CacheDir / "#{instrument.ticker} recommendations #{Date.current.to_s :number}.json"
      data = ApiCache.get CacheDir / "#{instrument.ticker} recommendations #{Date.current.to_s :number}.json" do
        puts "Load   recommendations for #{instrument.ticker}"
        Iex.recommedations(instrument.ticker)
      end

      import_iex_data instrument.ticker, data
      sleep delay

    rescue RestClient::NotFound => e
      puts "Recommendations load failed for #{instrument} with #{e}".red
    end

    def mark_current
      distinct.pluck(:ticker).sort.each do |ticker|
        transaction do
          recommendations = all.where(ticker: ticker).order(starts_on: :desc)
          first, *others = recommendations
          first.update! current: true
          others.each { |rec| rec.update! current: false }
        end
      end
    end
  end
end

__END__
Recommendation.import_iex_data_from_remote('aapl')
Recommendation.mark_current
