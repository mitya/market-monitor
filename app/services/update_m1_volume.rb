class UpdateM1Volume
  include StaticService

  def call
    m1_tickers = Candle::M1.distinct.pluck(:ticker)
    Instrument.where(ticker: m1_tickers).each do |i|
      info = i.info!
      info.extra ||= {}
      info.extra[:avg_m1_volume] = i.m1_candles.average(:volume).to_i
      info.save!
    end
  end
end
