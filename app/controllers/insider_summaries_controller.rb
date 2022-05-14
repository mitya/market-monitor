class InsiderSummariesController < ApplicationController
  def index
    # params[:ticker] = 'DK'
    @instrument = Instrument.get(params[:ticker])
    if @instrument
      @summaries = @instrument.insider_summaries
      PriceCache.preload @summaries
    else
      @summaries = []
    end
  end
end
