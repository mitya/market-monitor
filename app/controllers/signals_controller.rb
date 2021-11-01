class SignalsController < ApplicationController
  def index
    params[:dates] ||= [Current.yesterday.to_s]
    params[:per_page] ||= '400'
    params[:interval] ||= 'day'
    params[:direction] ||= 'up'
    params[:signal] ||= 'outside-bar'

    @signals = PriceSignal.all
    @signals = @signals.joins(:instrument)
    @signals = @signals.includes(:instrument => [:info, :price_target])

    @signals = @signals.for_interval params[:interval]                              if params[:interval].present?
    @signals = @signals.where date: params[:dates]                                  if params[:dates].any?
    @signals = @signals.where kind: params[:kind]                                   if params[:kind].present?
    @signals = @signals.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @signals = @signals.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @signals = @signals.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @signals = @signals.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @signals = @signals.where direction: params[:direction]                         if params[:direction].present?
    @signals = @signals.where on_level: true                                        if params[:only_levels].present?
    @signals = @signals.where 'volume_change >= ?', params[:volume_from]            if params[:volume_from].present?
    @signals = @signals.where 'volume_change <= ?', params[:volume_to]              if params[:volume_to].present?

    @signals = @signals.page(params[:page]).per(params[:per_page])

    @signals = @signals.order(:ticker, :date => :desc) if params[:interval] == 'day'
    @signals = @signals.order('date, time desc') if params[:interval] != 'day'

    Current.preload_prices_for @signals.map(&:instrument)
    Current.preload_day_candles_for @signals.map(&:instrument)
  end

  def intraday
    params[:dates] ||= [Current.date.to_s]
    params[:per_page] ||= '400'
    params[:interval] ||= '3min'
    params[:direction] ||= 'up'
    params[:signal] ||= ''
    index
    render
  end
end
