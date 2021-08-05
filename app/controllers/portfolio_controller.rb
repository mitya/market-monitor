class PortfolioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    item = PortfolioItem.find_or_create_by(ticker: params[:id])
    if params[:account]
      field = "#{params[:account]}_lots"
      item.update! field => params[:lots]
    elsif params.include?(:active)
      item.update! active: params[:active]
    end
    render json: item
  end

  def index
    @items = PortfolioItem.where('tinkoff_iis_lots > 0').order(:ticker)
    render partial: 'items'
  end
end
