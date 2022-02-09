class Setting < ApplicationRecord
  class << self
    def get(key, default = nil) = find_by_key(key)&.value || default
    def save(key, value) = find_or_create_by(key: key).update(value: value)
    def merge(key, hash) = save(key, get(key, {}).merge(hash.stringify_keys))
      
    def synced_tickers  = get('sync_tickers')
    def synced_instruments = Instrument.for_tickers(synced_tickers)
      
    def iex_last_update     = get('iex_last_update')&.to_time || 1.week.ago
    def tinkoff_last_update = get('tinkoff_last_update')&.to_time || 1.week.ago
      
    def chart_settings = get('chart_settings') || {}
    def chart_tickers  = chart_settings['tickers']
    def chart_period   = chart_settings['period']
    def chart_columns  = chart_settings['columns']
  end
end
