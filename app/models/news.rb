class News < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :for_tickers, -> tickers { where "? = any(tickers)", tickers }

  def cleared_body = body && body.to_s.gsub('👉 Show more', '').presence
  def other_tickers = tickers - [ticker]
  def title_with_body = "#{title} #{body}"

  def positive? = title_with_body.to_s =~ /raise|upgrade|success|blasts|positive/i
  def negative? = title_with_body.to_s =~ /downgrade|lower|failure|negative/i

  def sentiment
    positive = positive?
    negative = negative?
    case
      when positive && negative then 'mixed'
      when positive then 'positive'
      when negative then 'negative'
      else 'unknown'
    end
  end
end
