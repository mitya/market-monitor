class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    params[:per_page] ||= '200'
    load_instruments Instrument.all
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

    @instruments = Instrument.all
    @instruments = @instruments.left_joins(:aggregate, :info)
    @instruments = @instruments.preload(:aggregate, :info)
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?
    @instruments = @instruments.order("#{order} nulls last")
    @instruments = @instruments.page(params[:page]).per(params[:per_page])

    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @instruments.to_a
  end

  def grouped
    params[:per_page] = 1000
    @categories = YAML.load_file("db/categories.yaml").transform_values { |str| str.to_s.split.sort }
    load_instruments Instrument.where(ticker: @categories.values.flatten.compact.uniq)
    @instruments_index = @instruments.index_by &:ticker
    render :index
  end

  private

  def load_instruments(base)
    @instruments = base
    @instruments = @instruments.left_joins(:aggregate, :info)
    @instruments = @instruments.preload(:info, :price_target, :portfolio_item, :aggregate, :insider_aggregate, :portfolio_item)
    @instruments = @instruments.where(info: { industry: params[:industry] })       if params[:industry].present?
    @instruments = @instruments.where(info: { sector: params[:sector] })           if params[:sector].present?
    @instruments = @instruments.where(info: { sector_code: params[:sector_code] }) if params[:sector_code].present?
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.where(type: params[:type])                         if params[:type].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.with_alarm                                         if params[:alarm].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?

    # @instruments = @instruments.vtb_spb_long

    if params[:low] == '1'
      @instruments = @instruments.where('aggregates.lowest_day_date >= ?', params[:low_since]) if params[:low_since].present?
      @instruments = @instruments.where('aggregates.lowest_day_gain >= ?', params[:low_gain].to_f / 100) if params[:low_gain ].present?
    end

    order = params[:order].blank? || params[:order].include?('portfolio') ? 'instruments.ticker' : params[:order]
    @instruments = @instruments.order("#{order} nulls last")
    @instruments = @instruments.page(params[:page]).per(params[:per_page])

    @portfolio = PortfolioItem.all

    Current.preload_day_candles_with @instruments.to_a, params[:chart_volatility] ? Current.last_2_weeks : []
    Current.preload_prices_for @instruments.to_a
  end
end


__END__
Instrument.in_set(:portfolio).map(&:ticker).sort
