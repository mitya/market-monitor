class SetComparisionsController < ApplicationController
  def show
    @set_keys = %w[oil gas shipping]
    @set_keys = %w[xbi xhb xhs xlc xlf xli xlk xlp xlu xsd xlv xme xle xop xes xlb]
    @sets = @set_keys.map { |k| InstrumentSet.new(k) }

    Current.preload_day_candles_with :all, [] #, dates: [Current.yesterday]
    Current.preload_prices_for @sets.flat_map(&:instruments)
  end
end
