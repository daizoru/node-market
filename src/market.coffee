{inspect} = require 'util'
{delay} = require 'ragtime'
geekdaq = require 'geekdaq'

randInt = (min,max) -> Math.round(min + Math.random() * (max - min))

class module.exports

  constructor: (options={}) ->
    @server         = options.server         ? 'geekdaq'
    @codes          = options.tickers        ? []
    @updateInterval = options.updateInterval ? 500
    @commissions    = options.commissions    ? {buy: 0, sell: 0}
    errors =
      trivial: (x) -> x
      minor: (x) -> x
      major: (x) -> x
    @errors = options.errors ? errors


    @tickers = {}
    for code in @_codes
      @tickers[code] =
        func: geekdaq.generator
          range: 5
          levels: 150
        price: randInt 100, 400
        volume: randInt 100000, 400000

    @running = no

  # stock market data update frequency
  update: =>
    if @running
      for code, ticker of @tickers
        ticker.price += ticker.func()
      delay updateInterval, =>
        @update()

  stop: => 
    @running = no

  start: =>
    return if @running
    @running = yes
    @update()

  ticker: (code) => 
    @tickers[code]

  register: (account) =>
    @accounts[account.username] = account

  penalty: (username, amount) =>
    @accounts[account.username].balance -= amount

  execute: ({username, orders}) =>
    {trivial, minor, major} = @errors
    account = @accounts[username]
    for order in orders
      info "processing #{order.type} order:"
      ticker = @ticker order.ticker
      switch order.type
        when 'buy'
          raw_cost = order.amount * ticker.price
          #puts "raw cost: #{raw_cost}"
          total_cost = raw_cost + (raw_cost * @commissions.buy) # commission
          debug "total cost: #{total_cost}"

          if account.balance < total_cost
            alert trivial "cannot execute order: not enough money"
          else
            account.balance -= total_cost
            #log "order executed, balance is now #{worker.balance}"
            if order.symbol of account.portfolio
              account.portfolio[order.ticker] += order.amount
            else
              account.portfolio[order.ticker] = order.amount
            account.history.push
              type: order.type
              ticker: order.ticker
              amount: order.amount
              price: ticker.price
              total_cost: total_cost
        when 'sell'
          unless order.ticker of account.portfolio
            alert minor "invalid order: we do not own any #{order.ticker}"
            # for now, just let go
            #throw new Error "invalid order: we do not own any #{order.ticker}"
            return
          amount = account.portfolio[order.ticker]
          if amount < order.amount
            alert minor "invalid order: we do not have enough #{order.ticker} shares (want to sell #{order.amount}, but we have #{amount})"
            #throw new Error "invalid order: we do not have enough #{order.ticker} shares (want to sell #{order.amount}, but we have #{amount})"
            return
          raw_benefits = amount * ticker.price
          #log "raw benefits: #{raw_benefits}"
          total_benefits = raw_benefits - (raw_benefits * @commissions.sell) # commission
          debug "total benefits: #{total_benefits}"
          account.portfolio[order.ticker] -= order.amount
          account.balance += total_benefits
          account.history.push
            type: order.type
            ticker: order.symbol
            amount: order.amount
            price: ticker.price
            total_benefit: total_benefits
