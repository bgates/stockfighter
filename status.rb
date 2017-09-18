class Status

  attr_reader :holdings

  def initialize
    @cash = 0
    @holdings = 0
  end

  def update(buy_fills, sell_fills)
    #puts "cash at #{@cash}; holdings at #{@holdings}"
    #puts "buy fills #{buy_fills}"
    #puts "sell fills #{sell_fills}"
    @cash = @cash + cash_for(sell_fills) - cash_for(buy_fills)
    @holdings = @holdings + shares_of(buy_fills) - shares_of(sell_fills)
    puts "cash at #{@cash}; holdings at #{@holdings}"
  end

=begin
  def update(fills, direction)
    cash = cash_for(fills) * (direction == :buy ? -1 : 1)
    @cash = @cash + cash
    shares = shares_of(fills) * (direction == :sell ? -1 : 1)
    @holdings = @holdings + shares
  end
=end
  def cash_for(fills)
    fills.inject(0){|sum, fill| sum + fill['price'] * fill['qty']}
  end

  def shares_of(fills)
    fills.inject(0){|sum, fill| sum + fill['qty']}
  end

  def print_status(price)
    #puts "Cash: $#{@cash / 100} Holdings: #{@holdings} NAV: $#{present_value(price)}"
  end

  def present_value(current_price)
    (@holdings * current_price + @cash) / 100
  end

end

