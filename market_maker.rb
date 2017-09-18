require './order_maker'
require './status'
require './fill_reconciler'

class MarketMaker
  extend Forwardable

  def_delegators :@status, :holdings

  MAX_HOLDINGS = 1000
  MAX_SALES    = -1000

  def initialize
    @order_maker = OrderMaker.new
    @buy_orders, @sell_orders = @order_maker.first_transactions
    @status = Status.new
    @reconciler = FillReconciler.new
    @buy_fill_history = []
    @sell_fill_history = []
    sleep 4
  end

  def make_market
    loop do
      buy_fills = fills_from_canceled(cancel_buy_orders)
      sell_fills = fills_from_canceled(cancel_sell_orders)
      @buy_fill_history.concat buy_fills
      @sell_fill_history.concat sell_fills
      puts "buy fills: #{@buy_fill_history.map{|fill| {'price' => fill['price'], 'qty' => fill['qty']}}}"
      puts "sell fills: #{@sell_fill_history.map{|fill| {'price' => fill['price'], 'qty' => fill['qty']}}}"
      update_status(buy_fills, sell_fills)
      update_orders
      print_status
      puts "TOO LONG, STOP BUYING GODDAMIT" if too_long_position?
      puts "SHORT, STOP SELLING GODDAMIT" if too_short_position?
      sleep 9
    end
  end

private

  def cancel_buy_orders
    @buy_orders = @order_maker.cancel(@buy_orders)
  end

  def cancel_sell_orders
    @sell_orders = @order_maker.cancel(@sell_orders)
  end

  def fills_from_canceled(orders)
    orders.map{|order| order['fills']}.flatten
  end

  def update_status(new_buy_fills, new_sell_fills)
    @status.update(new_buy_fills, new_sell_fills)
    @reconciler.update(new_buy_fills, new_sell_fills)
  end

  def update_orders
    place_reconciliation_buy_orders unless too_long_position?
    place_reconciliation_sell_orders unless too_short_position?
    place_market_orders
    clean_up_orders
  end

  def too_long_position?
    holdings > 0.5 * MAX_HOLDINGS
  end

  def too_short_position?
    holdings < 0.5 * MAX_SALES
  end

  def place_market_orders
    market_buy, market_sell = @order_maker.place_market_orders(max_buy, max_sale, too_long_position?, too_short_position?)
    @buy_orders << market_buy if market_buy && market_buy['ok'] && market_buy['open']
    @sell_orders << market_sell if market_sell && market_sell['ok'] && market_sell['open']
  end

  def clean_up_orders
    [@buy_orders, @sell_orders].each do |orders|
      orders.reject!{|order| order.nil? || !order['ok'] || !order['open']}
    end
  end

  def place_reconciliation_buy_orders
    @reconciler.sell_fills.each do |fill|
      bid = fill['price'] - 75
      qty = fill['qty']
      unless cannot_buy?(qty)
        new_order = @order_maker.buy(qty, bid)
        @buy_orders << new_order if new_order['ok']
      end
    end
  end

  def place_reconciliation_sell_orders
    @reconciler.buy_fills.each do |fill|
      ask = fill['price'] + 75
      qty = fill['qty']
      unless cannot_sell?(qty)
        new_order = @order_maker.sell(qty, ask)
        @sell_orders << new_order if new_order['ok']
      end
    end
  end

  def cannot_buy?(qty)
    qty <= 0 || potential_buy_holdings(qty) > MAX_HOLDINGS / 2
  end

  def potential_buy_holdings(qty = 0)
    holdings + buy_orders_qty + qty
  end

  def max_buy
    MAX_HOLDINGS - potential_buy_holdings
  end

  def cannot_sell?(qty)
    qty <= 0 || potential_sell_holdings(qty) < MAX_SALES / 2
  end

  def potential_sell_holdings(qty = 0)
    holdings - sell_orders_qty - qty
  end

  def max_sale
    potential_sell_holdings - MAX_SALES
  end

  def buy_orders_qty
    @buy_orders.inject(0){|sum, order| sum + order['qty']}
  end

  def sell_orders_qty
    @sell_orders.inject(0){|sum, order| sum + order['qty']}
  end

  def print_status
    @status.print_status(@order_maker.current_price)
  end
end
