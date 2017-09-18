require './wrappers'

class MarketMaker

  def initialize
    game = start_game('chock_a_block')
    @account = game['account']
    @venue = game['venues'][0]
    @symbol = game['tickers'][0]
    @id = game['instanceId']
    @last = Hash.new(0)
    get_target
    puts "Target price #{@target}"
  end

  def make_market
    loop do
      cancel_buy if @buy
      web_cancel(@symbol, @venue, @sell['id']) if @sell
      puts "loop..."
      get_quote
      go_big || buy_sell_normal
      @last = @quote
      sleep 3
    end
  end

private

  def get_target
    until @target do
      start = quote(@symbol, @venue)
      buy(1, ((start['bid'] + start['last']) / 2).to_i) if start['bid'] && start['last']
      sleep 4
      current = game_info(@id)
      puts current
      @target = current['flash'] && current['flash']['info']
    end
    @target = @target.match(/target price is \$(\d+\.\d+)/)[1].to_f * 100
  end

  def buy(qty, price)
    limit_buy_order(account: @account, venue: @venue, stock: @symbol, price: price, qty: qty)
  end

  def cancel_buy
    cancel_buy = web_cancel(@symbol, @venue, @buy['id'])
    web_cancel(@symbol, @venue, @cheap['id'])
    puts "cancel #{cancel_buy['id']} for #{cancel_buy['price']} (open: #{cancel_buy['open']})"
  end

  def get_quote
    @quote = quote(@symbol, @venue)
    %w(bid last ask).each{|key| @quote[key] ||= 0}
  end

  def go_big
    return false if @quote['last'] >= @target * 0.4
    qty = [@quote['askSize'] * 2, 100].max
    price = [@quote['ask'], (@target * 0.4).to_i].max
    asking = buy(qty, price)
    puts "go for #{asking}"
  end

  def buy_sell_normal
    buy_normal
    sell_normal
  end

  def buy_normal
    bid = (( 9 * @quote['bid'] + @quote['last']) / 10).to_i
    unless @quote['bid'] == @last['bid'] || bid > @target
      puts "buying #{@quote['askSize']} @ ~#{bid}"
      @buy = buy(@quote['askSize'], bid)
      @cheap = buy(@quote['askSize'], (bid * 0.8).to_i)
    end
  end

  def sell_normal
    unless @quote['ask'] == @last['ask']
      qty = (@quote['bidSize'] * (1 + rand(10) / 10)).to_i
      price = ((@quote['ask'] + 9 * @quote['last']) / 10).to_i
      puts "selling #{qty} @ ~#{price}"
      @sell = limit_sell_order(account: @account, venue: @venue, stock: @symbol, price: price, qty: qty)
    end
  end

end

MarketMaker.new.make_market
=begin
@headers = ['wallTime', 'quoteTime', 'lastTrade', 'last', 'lastSize', 'bid', 'bidSize', 'ask', 'askSize', 'bidDepth', 'askDepth', ]
def save_book(csv)
  book = orderbook(@symbol, @venue)
  csv << Array.new(@headers.length){'*'}
  puts book
  csv << [book[:ts].sub(/[^:]+:/,'').sub(/\.(\d{3}).*/,'.\1')]
  book[:bids] && book[:bids].reverse.each do |bid|
    csv << ['', '', '', '', '', bid['price'], bid['qty']]
  end
  book[:asks] && book[:asks].each do |ask|
    csv << ['', '', '', '', '', '', '', ask['price'], ask['qty']]
  end
  csv << Array.new(@headers.length){'*'}
end

@orders = []
CSV.open("quotes.csv", "wb") do |csv|
  csv << @headers
  save_book(csv)
  prev = Hash.new(0)
  start = quote(@symbol, @venue)
  floor = start['last'] || start['bid'] || start['ask']
  600.times do
    last = quote(@symbol, @venue)
    if %w(lastTrade ask bid askSize bidSize).all?{|v| last[v] == prev[v]}
      @orders.each do |order|
        if order['price'].nil?
          puts "NIL: #{order}"
          @orders.delete(order)
        elsif order['price'] > last['bid'].to_i
          cancel(@symbol, @venue, order['id'])
          @orders.delete(order)
        end
      end
      price = [floor, last['bid'] || last['last']].min
      floor = price
      @orders << limit_sell_order(account: @account, venue: @venue, stock: @symbol, price: price - 2, qty: last['bidSize'])
      @orders << limit_sell_order(account: @account, venue: @venue, stock: @symbol, price: price - 5, qty: 100)
    end
    csv << [ Time.now.getutc.strftime("%M:%S.%L"), @headers.map{|h| last[h].is_a?(String) ? last[h].sub(/[^:]+:/,'').sub(/\.(\d{3}).*/,'.\1') : last[h]}].flatten.compact
    prev = last
    puts prev
  end
  save_book(csv)
end
=end
