class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    params[:per_page] ||= '200'
    params[:availability] ||= 'tinkoff'
    load_instruments Instrument.active
  end

  def export
    tickers = params[:tickers].to_s.split(' ')
    set = params[:set] || 'list'
    send_data tickers.join("\n"), filename: "#{set.humanize} #{Time.current.strftime('%Y-%m-%d %H:%M')}.txt"
  end

  def spb
    order = params[:order].presence || 'instruments.ticker'
    params[:currency] ||= 'USD'
    params[:availability] ||= 'tinkoff'
    params[:per_page] ||= 5000

    @instruments = Instrument.active
    @instruments = @instruments.left_joins(:aggregate_record, :info_record)
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?
    @instruments = @instruments.order("#{order} nulls last")
    @instruments = @instruments.page(params[:page]).per(params[:per_page])

    CandleCache.preload :all
    PriceCache.preload @instruments
  end

  def grouped
    params[:per_page] = 1000
    @categories = InstrumentSet.categories
    load_instruments Instrument.where(ticker: @categories.values.flatten.sort)
    @instruments_index = @instruments.index_by &:ticker
    render :index
  end

  private

  def load_instruments(base)
    @instruments = base
    @instruments = @instruments.left_joins(:aggregate_record, :info_record, :indicators_record, :price)
    @instruments = @instruments.preload(:price_target, :portfolio_item, :insider_aggregate, :portfolio_item)
    @instruments = @instruments.where(info_record: { industry: params[:industry] })       if params[:industry].present?
    @instruments = @instruments.where(info_record: { sector: params[:sector] })           if params[:sector].present?
    @instruments = @instruments.where(info_record: { sector_code: params[:sector_code] }) if params[:sector_code].present?
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.where(type: params[:type])                         if params[:type].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.with_alarm                                         if params[:alarm].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?
    @instruments = @instruments.where('indicators.ema_50_trend': params[:ma_50])   if params[:ma_50].present?
    @instruments = @instruments.where('indicators.ema_200_trend': params[:ma_200])   if params[:ma_200].present?

    if params[:low] == '1'
      @instruments = @instruments.where('aggregates.lowest_day_date >= ?', params[:low_since]) if params[:low_since].present?
      @instruments = @instruments.where('aggregates.lowest_day_gain >= ?', params[:low_gain].to_f / 100) if params[:low_gain ].present?
    end

    # @instruments = @instruments.where('aggregates.d1_money_volume <= ?', 10_000_000)

    @instruments = @instruments.order(InstrumentsSorter.determine_sort_order params[:order])
    @instruments = @instruments.page(params[:page]).per(params[:per_page])

    @portfolio = PortfolioItem.all

    CandleCache.preload @instruments, Current.last_2_weeks
    PriceCache.preload @instruments
  end
end
