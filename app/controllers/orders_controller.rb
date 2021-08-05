class OrdersController < ApplicationController

  def index
    @orders = Order.includes(:instrument)
    @buys   = @orders.select &:buy?
    @sells  = @orders.select &:sell?

    if request.xhr?
      render json: {
        buys: render_to_string(partial: 'orders_table', locals: { title: 'Buys', orders: @buys }),
        sells: render_to_string(partial: 'orders_table', locals: { title: 'Buys', orders: @sells })
      }
    end
  end
end
