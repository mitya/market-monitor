class SignalResultsController < ApplicationController
  def index
    params[:per_page] ||= '500'
    params[:since] = Current.ytd.to_s if params[:since].blank?
    params[:till]  = Current.date.to_s if params[:till].blank?
    params[:direction]  ||= 'up'
    params[:signal]  ||= 'breakout'
    params[:changed_more] = 0.12

    if params[:period].present?
      if params[:period] == 'All'
        params[:since], params[:till] = [nil, nil]
      else
        params[:since], params[:till] = params[:period].split('..')
      end
    end

    dates = params[:since].to_date .. params[:till].to_date if params[:since].present? || params[:till].present?

    @results = PriceSignalResult.all
    @results = @results.joins(:instrument, :signal)
    @results = @results.includes(:signal, :instrument => [:info, :price_target])

    @results = @results.where price_signals: { date: dates }                        if dates
    @results = @results.where price_signals: { kind: params[:signal] }              if params[:signal].present?
    @results = @results.where price_signals: { direction: params[:direction] }      if params[:direction].present?
    @results = @results.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @results = @results.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @results = @results.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @results = @results.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?

    PriceSignal::BreakoutFields.each do |var|
      if from = params["#{var}_from"].presence && params["#{var}_from"].to_f
        @results = @results.param_gte var, from / 100.0
      end
      if to = params["#{var}_to"].presence && params["#{var}_to"].to_f
        @results = @results.param_lte var, to / 100.0
      end
    end

    @unpaged_results = @results
    @results = @results.page(params[:page]).per(params[:per_page])
    @results = @results.order('price_signals.date', :ticker)

    @averages = {}
    %i[d1_close d1_max d2_close d2_max d3_close d3_max d4_close d4_max w1_close w1_max w2_close w2_max w3_close w3_max m1_close m1_max m2_close m2_max].each do |attr|
      @averages[attr] = @unpaged_results.average(attr)
    end

    Current.preload_prices_for @results.map(&:instrument)
    Current.preload_day_candles_for @results.map(&:instrument)
  end
end
