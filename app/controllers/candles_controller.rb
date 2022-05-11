class CandlesController < ApplicationController
  CHART_PERIODS = %w[
    2020-01-01
    2021-01-01
    2021-03-01
    2021-09-01
    2022-01-01
  ].map { |str| Date.parse str }.sort + [
    Current.d2_ago,
    Current.yesterday,
    Current.date,
  ]

  DEFAULT_PERIOD = Date.parse('2021-09-01')

  def index
    start_date = params[:since] ? Date.parse(params[:since]) : DEFAULT_PERIOD
    @instrument = Instrument.get!(params[:instrument_id])
    @candles = @instrument.day_candles.where('date > ?', start_date).order(:date)
    @levels = @instrument.levels.auto.select{ |level| @candles.any? { |c| c.range.include?(level.value) }}.sort_by(&:value).map do |level|
      {
        value: level.value,
        row: [ [@candles.first&.date, level.value] , [@candles.last&.date, level.value] ]
      }
    end
  end
end
