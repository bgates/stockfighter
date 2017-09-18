require './wrappers'
class OrderMaker

  def initialize
    game = start_game('sell_side')
    @account = game['account']
    @venue = game['venues'][0]
    @symbol = game['tickers'][0]
    @id = game['instanceId']
    get_quote
  end

  def first_transactions
    buys, sells = [], []
    while buys.empty? || sells.empty?
      first_buy = buy @quote["bidSize"], market_buy_price
      first_sell = sell @quote["askSize"], market_sale_price
      if first_buy['ok'] && first_sell['ok']
        buys << first_buy
        sells << first_sell
      else
        sleep 4
        get_quote
      end
    end
    [buys, sells]
  end

  def get_quote
    @quote = quote(@symbol, @venue)
    %w(bid last ask).each{|key| @quote[key] ||= 0}
    puts "Quote: bid #{@quote['bid']} / last #{@quote['last']} / ask #{@quote['ask']}"
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

  def place_market_orders(max_buy, max_sell, skip_buy, skip_sell)
    if skip_buy
      emergency_sell
    elsif skip_sell
      emergency_buy
    else
      get_quote
      market_qty = safe_qty(max_buy, max_sell)
      market_buy = buy_market(market_qty)
      market_sell = sell_market(market_qty)
      [market_buy, market_sell]
    end
  end

  def emergency_sell
    get_quote
    [{}, sell(300, @quote['bid'] + 100)]
  end

  def emergency_buy
    get_quote
    [{}, buy(300, @quote['ask'] - 100)]
  end

  def safe_qty(max_buy, max_sell)
    market_size = [@quote['bidSize'], @quote['askSize']].max
    [market_size, max_buy, max_sell].min
  end

  def buy_market(qty)
    buy(qty, market_buy_price) unless qty <= 0
  end

  def sell_market(qty)
    sell(qty, market_sale_price) unless qty <= 0
  end

  def market_buy_price
    return @quote['ask'] if @quote['bid'] == 0
    ((9 * @quote['bid'] + @quote['ask']) / 10).to_i
  end

  def market_sale_price
    return @quote['bid'] if @quote['ask'] == 0
    ((9 * @quote['ask'] + @quote['bid']) / 10).to_i
  end

  def current_price
    @quote['last'] || @quote['bid']
  end

end

