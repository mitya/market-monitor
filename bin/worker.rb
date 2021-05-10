#!/usr/bin/env ruby

load "config/environment.rb"

$PROGRAM_NAME = "trading-worker"
$hour_loaded_at = Date.yesterday

def load_hours
  Instrument.main.tinkoff.abc.each { |inst| Tinkoff.import_intraday_candles(inst, 'hour') }
  analyze
end

def load_5mins
  Instrument.main.tinkoff.abc.each { |inst| Tinkoff.import_intraday_candles(inst, '5min') }
  analyze
end

def update_tinkoff_prices
  Price.refresh_from_tinkoff Instrument.where(currency: %w[RUB EUR]).abc
end

def update_iex_prices
  Price.refresh_from_iex
end

def analyze
  PriceSignal.intraday.delete_all
  [Candle::H1, Candle::M5].each do |candle_class|
    candle_class.where(date: Current.date).non_analyzed.find_each do |candle|
      PriceSignal.analyze_intraday candle
    end
  end
end

while true
  break if Current.weekend?
  puts "check.."

  analyze

  current_minute = Time.current.min

  case
  when current_minute == 0 # || $hour_loaded_at < 5.minutes.ago
    load_hours
    load_5mins
  when current_minute % 5 == 0
    load_5mins
    update_iex_prices
    update_tinkoff_prices
  end

  sleep 5
end
