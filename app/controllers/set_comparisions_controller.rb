class SetComparisionsController < ApplicationController
  def show
    # @set_keys = %w[oil gas shipping]
    # @set_keys = %w[xbi xhb xhs xlc xlf xli xlk xlp xlu xsd xlv xme xle xop xes xlb]

    InstrumentSet.reload_categories!

    @set_groups = [
      # %w[gainers_us],
      # %w[losers_us],
      %w[gainers_ru],
      %w[losers_ru],
      # %w[mine.us mine.ru],
      # %w[watch.us watch.ru extremes],
      # %w[energy.oil energy.oil.refinery energy.oil.service],
      # %w[energy.gas energy.coal* energy.uranium mining.fertilizers],
      # %w[mining.steel mining.gold mining.misc],
      # %w[shipping*],
      # %w[it.faang it.hot it.games],
      # %w[biotech*],
      # %w[reit retail],
      # %w[china travelling transportation.airlines],
    ]

    # retail covid

    @set_groups = @set_groups.map do |keys|
      Array(keys).map { |k| InstrumentSet.new k, :category, period: params[:selector] }
    end

    preload_associations
  end

  def summary
    selector = 'd1'
    volume_expr = "data->'volumes'->'#{selector}'"
    @volume_gainers = Aggregate.current.order(Arel.sql "#{volume_expr} desc nulls last").limit(50).pluck(:ticker)
    @volume_losers  = Aggregate.current.order(Arel.sql "#{volume_expr}  asc nulls last").where("(#{volume_expr})::float > 0").limit(50).pluck(:ticker)

    @hits = PriceLevelHit.where(date: Current.yesterday).where('days_since_last > ?', 20).all
    p @hits.map(&:ticker)
    @hits_sets = {
      level_up_tests:    @hits.levels.select {                        _1.kind.in?(%w[up-test]) },
      level_up_breaks:   @hits.levels.select {                        _1.kind.in?(%w[up-break up-gap]) },
      level_down_tests:  @hits.levels.select {                        _1.kind.in?(%w[down-test]) },
      level_down_breaks: @hits.levels.select {                        _1.kind.in?(%w[down-break down-gap]) },
      ma200_up_tests:    @hits.ma.    select { _1.ma_length == 200 && _1.kind.in?(%w[up-test]) },
      ma200_up_breaks:   @hits.ma.    select { _1.ma_length == 200 && _1.kind.in?(%w[up-break up-gap]) },
      ma200_down_tests:  @hits.ma.    select { _1.ma_length == 200 && _1.kind.in?(%w[down-test]) },
      ma200_down_breaks: @hits.ma.    select { _1.ma_length == 200 && _1.kind.in?(%w[down-break down-gap]) },
      ma50_up_tests:     @hits.ma.    select { _1.ma_length ==  50 && _1.kind.in?(%w[up-test]) },
      ma50_up_breaks:    @hits.ma.    select { _1.ma_length ==  50 && _1.kind.in?(%w[up-break up-gap]) },
      ma50_down_tests:   @hits.ma.    select { _1.ma_length ==  50 && _1.kind.in?(%w[down-test]) },
      ma50_down_breaks:  @hits.ma.    select { _1.ma_length ==  50 && _1.kind.in?(%w[down-break down-gap]) },
    }
    get_instruments = -> key { InstrumentSet.new(key, :static, items: @hits_sets[key].pluck(:ticker)) }

    @spikes = Spike.where(date: Current.yesterday) #.order(ticker: :asc).includes(:instrument => [:aggregate])
    p @spikes.map(&:ticker)
    @spikes_index = @spikes.index_by &:ticker
    ups, downs = @spikes.partition &:up?

    @set_groups = [
      [ get_instruments.(:ma200_up_tests),    get_instruments.(:ma50_up_tests), get_instruments.(:level_up_tests)       ],
      [ get_instruments.(:ma200_up_breaks),   get_instruments.(:ma50_up_breaks), get_instruments.(:level_up_breaks)     ],
      [ get_instruments.(:ma200_down_tests),  get_instruments.(:ma50_down_tests), get_instruments.(:level_down_tests)   ],
      [ get_instruments.(:ma200_down_breaks), get_instruments.(:ma50_down_breaks), get_instruments.(:level_down_breaks) ],
      [
        InstrumentSet.new(:volume_gainers, :static, items: @volume_gainers),
        InstrumentSet.new(:volume_losers,  :static, items: @volume_losers)
      ],
      [
        InstrumentSet.new(:spikes_up,   :static, items:   ups.pluck(:ticker)),
        InstrumentSet.new(:spikes_down, :static, items: downs.pluck(:ticker))
      ],

    ]

    preload_associations
  end

  private

  def preload_associations
    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @set_groups.flatten.flat_map(&:instruments)
  end
end
