class SignalResultsController < ApplicationController
  def index
    params[:per_page] ||= '500'
    params[:since] ||= '2021-03-01'
    params[:till]  ||= Date.current.to_s

    dates = params[:since].to_date .. params[:till].to_date if params[:since].present? || params[:till].present?

    @results = PriceSignalResult.all
    @results = @results.joins(:instrument, :signal)
    @results = @results.includes(:signal, :instrument => [:info, :price_target])

    # @results = @results.where signal: { date: dates }                               if dates
    @results = @results.where price_signals: { kind: params[:signal] }              if params[:signal].present?
    @results = @results.where price_signals: { direction: params[:direction] }      if params[:direction].present?
    @results = @results.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @results = @results.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @results = @results.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @results = @results.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?

    @results = @results.page(params[:page]).per(params[:per_page])
    @results = @results.order('price_signals.date', :ticker)

    @averages = {}
    %i[d1_close d1_max d2_close d2_max d3_close d3_max w1_close w1_max w2_close w2_max m1_close m1_max m2_close m2_max].each do |attr|
      @averages[attr] = @results.average(attr)
    end

    Current.preload_prices_for @results.map(&:instrument)
    Current.preload_day_candles_for @results.map(&:instrument)
  end
end
