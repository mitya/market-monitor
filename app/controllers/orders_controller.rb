class OrdersController < ApplicationController

  def index
    @orders = Order.includes(:instrument)
    @buys   = @orders.select &:buy?
    @sells  = @orders.select &:sell?

    on_xhr_render :orders
  end
end
