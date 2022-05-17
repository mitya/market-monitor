class SpikesController < ApplicationController
  def index
    params[:per_page] ||= '400'

    @spikes = Spike.order(date: :desc, ticker: :asc)
    @spikes = @spikes.joins(:instrument)
    @spikes = @spikes.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @spikes = @spikes.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @spikes = @spikes.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @spikes = @spikes.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @spikes = params[:direction] == 'up' ? @spikes.up : @spikes.down              if params[:direction].present?
    @spikes = @spikes.page(params[:page]).per(params[:per_page])

    PriceCache.preload @spikes
    CandleCache.preload @spikes
  end
end
