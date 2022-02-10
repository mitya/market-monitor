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
    base_scope = PriceLevelHit.where(date: Current.yesterday).where('days_since_last > ?', 20)
    hits_sets = {
      ma200_up_tests:    base_scope.where(source: 'ma', ma_length: 200, kind: %w[up-test]),
      ma200_up_breaks:   base_scope.where(source: 'ma', ma_length: 200, kind: %w[up-break up-gap]),
      ma200_down_tests:  base_scope.where(source: 'ma', ma_length: 200, kind: %w[down-test]),
      ma200_down_breaks: base_scope.where(source: 'ma', ma_length: 200, kind: %w[down-break down-gap]),
      ma50_up_tests:     base_scope.where(source: 'ma', ma_length:  50, kind: %w[up-test]),
      ma50_up_breaks:    base_scope.where(source: 'ma', ma_length:  50, kind: %w[up-break up-gap]),
      ma50_down_tests:   base_scope.where(source: 'ma', ma_length:  50, kind: %w[down-test]),
      ma50_down_breaks:  base_scope.where(source: 'ma', ma_length:  50, kind: %w[down-break down-gap]),
    }

    @set_groups = hits_sets.map do |key, hit_set|
      [ InstrumentSet.new(key, :static, items: hit_set.pluck(:ticker)) ]
    end

    preload_associations
  end

  private

  def preload_associations
    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @set_groups.flatten.flat_map(&:instruments)
  end
end
