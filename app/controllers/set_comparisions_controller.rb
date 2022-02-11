class SetComparisionsController < ApplicationController
  def show
    # @set_keys = %w[oil gas shipping]
    # @set_keys = %w[xbi xhb xhs xlc xlf xli xlk xlp xlu xsd xlv xme xle xop xes xlb]

    InstrumentSet.reload_categories!

    @set_groups = [
      %w[gainers_us],
      %w[losers_us],
      %w[gainers_ru],
      %w[losers_ru],
      %w[mine.us mine.ru],
      %w[watch.us watch.ru extremes],
      %w[energy.oil energy.oil.refinery energy.oil.service],
      %w[energy.gas energy.coal*],
      %w[mining.steel mining.gold mining.misc],
      %w[shipping*],
      %w[it.faang it.hot it.games],
      %w[biotech*],
      %w[reit retail],
      %w[china travelling transportation.airlines],
    ]

    # retail covid

    @set_groups = @set_groups.map do |keys|
      Array(keys).map { |k| InstrumentSet.new k, :category, period: params[:selector] }
    end

    preload_associations
  end

  def summary
    d1_volume_expr = "data->'volumes'->'d1'"
    @volume_gainers = Aggregate.current.order(Arel.sql "#{d1_volume_expr} desc nulls last").limit(50).pluck(:ticker)
    @volume_losers  = Aggregate.current.order(Arel.sql "#{d1_volume_expr}  asc nulls last").where("(#{d1_volume_expr})::float > 0").limit(50).pluck(:ticker)

    @hits = PriceLevelHit.where(date: Current.yesterday, source: 'ma').where('days_since_last > ?', 20).all
    @hits_sets = {
      ma200_up_tests:    @hits.select { _1.ma_length == 200 && _1.kind.in?(%w[up-test]) },
      ma200_up_breaks:   @hits.select { _1.ma_length == 200 && _1.kind.in?(%w[up-break up-gap]) },
      ma200_down_tests:  @hits.select { _1.ma_length == 200 && _1.kind.in?(%w[down-test]) },
      ma200_down_breaks: @hits.select { _1.ma_length == 200 && _1.kind.in?(%w[down-break down-gap]) },
      ma50_up_tests:     @hits.select { _1.ma_length ==  50 && _1.kind.in?(%w[up-test]) },
      ma50_up_breaks:    @hits.select { _1.ma_length ==  50 && _1.kind.in?(%w[up-break up-gap]) },
      ma50_down_tests:   @hits.select { _1.ma_length ==  50 && _1.kind.in?(%w[down-test]) },
      ma50_down_breaks:  @hits.select { _1.ma_length ==  50 && _1.kind.in?(%w[down-break down-gap]) },
    }    
    
    get_instruments = -> key { InstrumentSet.new(key, :static, items: @hits_sets[key].pluck(:ticker)) }
    @set_groups = [
      [ get_instruments.(:ma200_up_breaks),   get_instruments.(:ma50_up_breaks)   ],
      [ get_instruments.(:ma200_up_tests),    get_instruments.(:ma50_up_tests)    ],
      [ get_instruments.(:ma200_down_breaks), get_instruments.(:ma50_down_breaks) ],
      [ get_instruments.(:ma200_down_tests),  get_instruments.(:ma50_down_tests)  ],
      [ InstrumentSet.new(:volume_gainers, :static, items: @volume_gainers), InstrumentSet.new(:volume_losers,  :static, items: @volume_losers) ],
    ]    
    
    preload_associations
  end

  private

  def preload_associations
    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @set_groups.flatten.flat_map(&:instruments)
  end
end
