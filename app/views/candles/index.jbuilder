json.call @instrument, :ticker, :name
json.trading_view_url trading_view_url(@instrument)
json.candles @candles do |candle|
  json.date candle.date
  json.ohlc candle.ohlc_row
  json.volume candle.volume
end
