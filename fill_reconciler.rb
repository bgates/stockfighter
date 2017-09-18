class FillReconciler
  attr_reader :buy_fills, :sell_fills

  def initialize
    @buy_fills = []
    @sell_fills = []
  end

  def update(new_buy_fills, new_sell_fills)
    @buy_fills = add_fills(new_buy_fills, @buy_fills)
    @sell_fills = add_fills(new_sell_fills, @sell_fills)
    reconcile_fills
  end

  def add_fills(new_fills, fills)
    fills.concat new_fills
    fills.group_by{|h| h['price']}.map do |k,v|
      {'price' => k, 'qty' => v.inject(0){|sum, h| sum + h['qty']}}
    end
  end

  def reconcile_fills
    @buy_fills.sort_by{|fill| fill['price']}.reverse.each do |fill|
      reconcile_purchase(fill)
      @sell_fills.reject!{|sell_fill| sell_fill['qty'] == 0}
    end
    @buy_fills.reject!{|fill| fill['qty'] == 0}
  end

  def reconcile_purchase(fill)
    sells_filled_for_more_than(fill['price']).each do |sell|
      break if fill['qty'] == 0
      next if sell['qty'] == 0
      reconcile(fill, sell)
    end
  end

  def sells_filled_for_more_than(price)
    @sell_fills.select{|fill| fill['price'] >= price}.sort_by{|fill| fill['price']}
  end

  def reconcile(fill, other_fill)
    if fill['qty'] > other_fill['qty']
      fill['qty'] -= other_fill['qty']
      other_fill['qty'] = 0
    else
      other_fill['qty'] -= fill['qty']
      fill['qty'] = 0
    end
  end

end

