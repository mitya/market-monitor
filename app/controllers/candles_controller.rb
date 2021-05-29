class CandlesController < ApplicationController
  def index
    @instrument = Instrument.get!(params[:instrument_id])
    @candles = @instrument.day_candles.where('date > ?', Date.current.beginning_of_year)
  end
end
