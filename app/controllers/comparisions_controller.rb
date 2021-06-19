class ComparisionsController < ApplicationController
  def show
    params[:base_date]  ||= MarketCalendar.closest_weekday(Current.date.beginning_of_month).to_s(:db)
    params[:start_date] ||= (Current.date.beginning_of_month - 2).to_s(:db)

    # params[:base_date] = '2021-04-30'
    # params[:start_date] = '2021-04-15'

    tickers = params[:tickers].to_s.split(' ')
    comparision = Comparision.new(params[:base_date].to_date)
    @dates = MarketCalendar.open_days(params[:start_date])
    @values = comparision.values_for_all(tickers, @dates).map { |ticker, data| { name: ticker, data: data } }

    # render json: {
    #   data: comparision.values_for_all(tickers, params[:start_date])
    # }
  end
end


__END__

/comparision?tickers=DK+FANG+CLR+XOM+RDS.A&base_date=2021-05-20&start_date=2021-05-01
