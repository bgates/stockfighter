require './wrappers'
class OrderMaker

  def initialize
    game = start_game('sell_side')
    @account = game['account']
    @venue = game['venues'][0]
    @symbol = game['tickers'][0]
    @id = game['instanceId']
    @quote_history = { bid: [], ask: [], last: [], bidSize: [], askSize: [] }
    get_quote
  end

  def first_orders
    loop do
      order = bigger_order
      if order['ok'] && order['originalQty'] > 0
        return [order]
      else
        sleep 4
        get_quote
      end
    end
  end

  def bigger_order
    if most_recent(:bidSize) > most_recent(:askSize)
      buy most_recent(:bidSize), market_buy_price
    else
      sell most_recent(:askSize), market_sale_price
    end
  end

  def place(direction, fills)
    get_quote
    qty = [most_recent(:bidSize), most_recent(:askSize)].max
    price = price_for(direction, fills)
    price == 0 ? [{'fills' => [], 'ok' => false}] : [send(direction, qty, price)]
  end

  def price_for(direction, fills)
    return 0 if fills.empty?
    if direction == :buy
      ([price_of(fills).min * 0.9, most_recent(:bid), most_recent(:last)].min * 1.05).to_i
    else
      ([price_of(fills).max * 1.05, most_recent(:ask), most_recent(:last)].max * 0.95).to_i
    end
  end

  def price_of(fills)
    fills.map{|fill| fill['price']}.compact
  end

  def get_quote
    @quote = quote(@symbol, @venue)
    @quote_history.each{|k,v| v << @quote[k.to_s] if @quote[k.to_s] && @quote[k.to_s] > 0}
    puts "Quote: bid #{most_recent(:bid)} / last #{most_recent(:last)} / ask #{most_recent(:ask)}"
  end

  def most_recent(type)
    @quote_history[type].last
  end

  def buy(qty, price)
    #puts "buy order: #{qty} @ #{price}"
    limit_buy_order(account: @account, venue: @venue, stock: @symbol, price: price, qty: qty)
  end

  def cancel(orders)
    orders.map! do |order|
      while order['open']
        order = web_cancel(@symbol, @venue, order['id'])
      end
      order
    end
  end

  def sell(qty, price)
    #puts "sell order: #{qty} @ #{price}"
    limit_sell_order(account: @account, venue: @venue, stock: @symbol, price: price, qty: qty)
  end

  def market_buy_price
    ((9 * most_recent(:bid) + most_recent(:ask)) / 10).to_i
  end

  def market_sale_price
    ((9 * most_recent(:ask) + most_recent(:bid)) / 10).to_i
  end

  def current_price
    @quote['last'] || @quote['bid']
  end

end


