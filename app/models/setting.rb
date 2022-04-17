class Setting < ApplicationRecord
  class << self
    def get(key, default = nil) = find_by_key(key)&.value || default
    def save(key, value) = find_or_create_by(key: key).update(value: value)
    def merge(key, hash) = save(key, get(key, {}).merge(hash.stringify_keys))
    alias set save

    def sync_tickers       = get('sync_tickers')
    def sync_ticker_sets   = get('sync_ticker_sets') || false

    def iex_last_update         = get('iex_last_update')&.to_time || 1.week.ago
    def iex_update_pending?     = get('iex_update_pending') || false
    def tinkoff_last_update     = get('tinkoff_last_update')&.to_time || 1.week.ago
    def tinkoff_update_pending? = get('tinkoff_update_pending') || false

    def chart_settings = get('chart_settings') || {}
    def chart_tickers  = chart_settings['tickers']
    def chart_period   = chart_settings['period']
    def chart_columns  = chart_settings['columns']

    def replace_chart_ticker(ticker)
      setting = find_by_key('chart_settings')
      tickers = setting.value['tickers']
      tickers[0] = ticker
      setting.save!
    end
  end
end
