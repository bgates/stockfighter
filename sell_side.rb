require './market_maker'
#require './mm2'

MarketMaker.new.make_market

# what is my goal here? I don't want to be long or short. I want to make money.
# each fill generates a basis. I want to make money on each fill.
# once I buy, I can't sell unless it's for more.
# once I sell, I can't buy unless it's for less.
# @ start, buy just above bid and sell just below ask
# next tick, cancel that order, hold on to fills
# make next round of transactions based on fills
# then do matching
# take fills from a buy
# compare to previous fills from sell
# try to take worst (lowest price sells) off the books
# sells will look like [{p: 11, q: 20}, {p: 14, q: 5}, {p: 19, q: 1}]
# latest buy fills [{p: 12, q: 4}, {p: 16, q: 9}, {p: 21, q: 2}]
# sort sells by their price, then iterate over them
# for each sell, iterate over buys (also sorted by price)
# look for buy w lower price than matched sell
# if it's not found, that sell is unmutated
# if there is a buy w lower price than a sell (ex p 12 buy vs p 14 sell),
# reduce the quantities of each
