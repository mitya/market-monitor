class CandlesController < ApplicationController
  def index
    start_date = Date.current.beginning_of_year
    start_date = Date.parse('2020-01-01')
    start_date = Date.parse('2021-03-01')
    start_date = Date.parse('2020-01-01')
    @instrument = Instrument.get!(params[:instrument_id])
    @candles = @instrument.day_candles.where('date > ?', start_date).order(:date)
    @levels = @instrument.levels.select{ |level| @candles.any? { |c| c.range.include?(level.value) }}.sort_by(&:value).map do |level|
      {
        value: level.value,
        row: [ [@candles.first&.date, level.value] , [@candles.last&.date, level.value] ]
      }
    end
  end
end
