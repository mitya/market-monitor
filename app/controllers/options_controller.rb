class OptionsController < ApplicationController
  def index
    @instrument = Instrument.get params[:instrument_id]
    @soonest_dates = @instrument.option_items.order(:date).where('date >= ?', Current.date).distinct.pluck(:date).first(3)

    @options_per_date = @soonest_dates.each_with_object({}) do |date, map|
      map[date] = OptionItem.latest_for_date params[:instrument_id], date
    end
    @strikes = @options_per_date.values.flatten.map(&:strike).uniq.sort
  end

  def show
    @date = params[:id]
    @instrument = Instrument.get params[:instrument_id]
    @options = OptionItem.latest_for_date params[:instrument_id], @date
    @strikes = @options.map(&:strike).uniq.sort
  end

  def history
    @instrument = Instrument.get params[:instrument_id]
    @date = params[:id]
    @options = @instrument.option_items.where(date: @date)
    @update_dates = @options.map(&:updated_on).uniq.sort.last(30)
    @strikes = @options.map(&:strike).uniq.sort
    CandleCache.preload [@instrument], @update_dates
    render :show
  end
end
