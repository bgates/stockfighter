require 'httparty'
require './constants'

def generic_order(account, venue, stock, price, qty, direction, order_type)
    order = {
      'account' => account,
      'venue'   => venue,
      'symbol'  => stock,
      'price'   => price,
      'qty'     => qty,
      'direction' => direction,
      'orderType' => order_type
    }
  api_interaction :post, "venues/#{venue}/stocks/#{stock}/orders",
    header, JSON.dump(order)
end

def header
  { 'X-Stockfighter-Authorization' => API_KEY }
end
# limit - match any order w price as good or better than mine (even if quantity < qty)
def limit_buy_order(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'buy', 'limit')
end

def limit_sell_order(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'sell', 'limit')
end

# limit, but won't execute unless qty shares available at price
def fok_buy(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'buy', 'fill-or-kill')
end

def fok_sell(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'sell', 'fill-or-kill')
end

# limit, but cancels whatever can't be filled immediately
def ioc_buy(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'buy', 'immediate-or-cancel')
end

def ioc_sell(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, price, qty, 'sell', 'immediate-or-cancel')
end

# market - for suckers
def market_buy_order(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, nil, qty, 'buy', 'market')
end

def market_sell_order(account:, venue:, stock:, price:, qty:)
  generic_order(account, venue, stock, nil, qty, 'sell', 'market')
end

def live?
  api_interaction(:get, 'heartbeat')['ok'] rescue false
end

def orderbook(stock, venue)
  response = api_interaction :get, "venues/#{venue}/stocks/#{stock}"
  { bids: response["bids"],  asks: response["asks"], ts: response["ts"] }
end

def quote(stock, venue)
  api_interaction :get, "venues/#{venue}/stocks/#{stock}/quote"
end

def status(stock, venue, account)
  api_interaction :get, "venues/#{venue}/accounts/#{account}/stocks/#{stock}/orders", header
end

def order_status(stock, venue, id)
  api_interaction :get, "venues/#{venue}/stocks/#{stock}/orders/#{id}", header
end

def cancel(stock, venue, order_id)
  api_interaction :delete, "/venues/#{venue}/stocks/#{stock}/orders/#{order_id}", header
end

def web_cancel(stock, venue, order_id)
  response = HTTParty.post "https://www.stockfighter.io/ob/api/venues/#{venue}/stocks/#{stock}/orders/#{order_id}/cancel", { headers: header, body: {} }
  response.parsed_response
end

def api_interaction(verb, url, headers = {}, order = {})
  response = HTTParty.send verb, "#{HTTP_BASE_URL}/#{url}", {headers: headers, body: order }
  response.parsed_response
end

def start_game(level)
  response = HTTParty.send :post, "#{GAME_URL}/levels/#{level}", {headers: header}
  response.parsed_response
end

def game_info(instance)
  response = HTTParty.send :get, "#{GAME_URL}/instances/#{instance}", {headers: header}
  response.parsed_response
end
