class PortfolioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    @item = PortfolioItem.find_or_create_by(ticker: params[:id])
    @item.update! lots: params[:lots]
    render json: @item
  end
end
