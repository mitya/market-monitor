class SetComparisionsController < ApplicationController
  def show
    @set_keys = %w[oil gas shipping]
    # @set_keys = %w[xbi xhb xhs xlc xlf xli xlk xlp xlu xsd xlv xme xle xop xes xlb]
    @set_keys = %w[energy.oil* energy.gas energy.coal it.faang shipping* mining.steel]
    @sets = @set_keys.map { |k| InstrumentSet.new(k, :category) }

    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @sets.flat_map(&:instruments)
  end
end
