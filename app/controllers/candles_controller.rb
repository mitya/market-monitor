class CandlesController < ApplicationController
  def index
    start_date = Date.current.beginning_of_year
    start_date = Date.parse('2021-03-01')
    start_date = Date.parse('2021-04-01')
    @instrument = Instrument.get!(params[:instrument_id])
    @candles = @instrument.day_candles.where('date > ?', start_date).order(:date)
  end
end
