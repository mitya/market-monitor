class Setting < ApplicationRecord
  class << self
    def get(key, default = nil) = find_by_key(key)&.value || default
    def save(key, value) = find_or_create_by(key: key).update(value: value)
      
    def synced_tickers  = Setting.get('synced_tickers')
    def chart_tickers   = Setting.get('chart_tickers')
    def chart_period    = Setting.get('chart_period')
    def chart_columns   = Setting.get('chart_columns')
    def iex_last_update     = Setting.get('iex_last_update')&.to_time || 1.week.ago
    def tinkoff_last_update = Setting.get('tinkoff_last_update')&.to_time || 1.week.ago
      
    def synced_instruments = Instrument.for_tickers(synced_tickers)
  end
end
