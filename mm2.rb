require './om'
require './status'

class MarketMaker
  extend Forwardable

  def_delegators :@status, :holdings

  MAX_HOLDINGS = 1000
  MAX_SALES    = -1000

  def initialize
    @order_maker = OrderMaker.new
    @orders = @order_maker.first_orders
    @status = Status.new
    @direction = first_direction
  end

  def make_market
    loop do
      sleep 4
      fills = fills_from_canceled(cancel_orders)
      puts "fills #{fills}"
      update_status(fills)
      print_status
      switch_direction
      place_orders(fills)
      puts "orders #{@orders}"
    end
  end

private

  def cancel_orders
    @orders = @order_maker.cancel(@orders)
  end

  def fills_from_canceled(orders)
    orders.map{|order| order['fills']}.flatten
  end

  def first_direction
    @orders.first['direction'].to_sym
  end

  def switch_direction
    @direction = @direction == :buy ? :sell : :buy
  end

  def update_status(new_fills)
    @status.update(new_fills, @direction)
  end

  def print_status
    @status.print_status(@order_maker.current_price)
  end

  def place_orders(fills)
    @orders = @order_maker.place(@direction, fills)
  end
end

