class SetComparisionsController < ApplicationController
  def show
    # @set_keys = %w[oil gas shipping]
    # @set_keys = %w[xbi xhb xhs xlc xlf xli xlk xlp xlu xsd xlv xme xle xop xes xlb]

    @set_groups = [
      %w[energy.oil energy.oil.refinery energy.oil.service],
      %w[energy.gas energy.coal*],
      %w[mining.steel mining.gold mining.misc],
      %w[shipping*],
      %w[biotech*],
      %w[it.faang it.hot it.games],
      %w[reit retail],
      %w[china travelling transportation.airlines],
    ]

    # retail covid

    @set_groups = @set_groups.map do |keys|
      Array(keys).map { |k| InstrumentSet.new(k, :category) }
    end

    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @set_groups.flatten.flat_map(&:instruments)
  end
end
