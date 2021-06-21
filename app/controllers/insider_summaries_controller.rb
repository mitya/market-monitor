class InsiderSummariesController < ApplicationController
  def index
    # params[:ticker] = 'DK'
    @instrument = Instrument.get(params[:ticker])
    if @instrument
      @summaries = @instrument.insider_summaries
      @summaries = @summaries.includes(:instrument => :info)
      Current.preload_prices_for @summaries.map &:instrument
    else
      @summaries = []
    end
  end
end
