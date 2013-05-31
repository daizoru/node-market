{inspect} = require 'util'
Stream    = require 'stream'

geekdaq = require 'geekdaq'

delay = (t,f) -> setTimeout f, t

pretty = (obj) -> "#{inspect obj, no, 20, yes}"

randInt = (min,max) -> Math.round(min + Math.random() * (max - min))
isString = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

log = console.log 

class module.exports extends Stream

  constructor: (options={}) ->
    @server         = options.server         ? 'geekdaq'
    @codes          = options.tickers        ? []
    @updateInterval = options.updateInterval ? 500
    @commissions    = options.commissions    ? {buy: 0, sell: 0}

    # pre-defined accoutns loader (accept either a map or an array)
    accounts        = options.accounts       ? []
    @accounts = {}
    if Array.isArray accounts
      for account in accounts
        @accounts[account.username] = account
    else
      for k,v of accounts
        @accounts[k] = v

    @tickers = {}
    for code in @codes
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
      delay @updateInterval, =>
        @update()
    else
      @emit 'stopped'

  stop: => 
    @emit 'stopping'
    if @running
      @running = no
      return
    @emit 'stopped'

  start: =>
    @emit 'starting'
    if @running
      @emit 'started'
      return
    @running = yes
    @emit 'started'
    @update()

  ticker: (t) => 
    if isString(t) then @tickers[t] else t

  register: (account) =>
    @accounts[account.username] = account
    @emit 'registration', account.username

  transfert: (username, amount, origin) =>
    @accounts[username].balance += amount
    if origin?
      @accounts[origin].balance -= amount
      @emit 'transfert', username, amount, origin
    else
      @emit 'transfert', username, amount


  execute: ({username, orders, onComplete}) =>
    account = @accounts[username]
    @emit 'debug', "username: #{username} and account: #{pretty account}"
    for order in orders
      @emit 'debug', "going to #{order.type} #{order.amount} #{order.ticker}:"
      ticker = @ticker order.ticker
      switch order.type
        when 'buy'
          raw_cost = order.amount * ticker.price
          #puts "raw cost: #{raw_cost}"
          total_cost = raw_cost + (raw_cost * @commissions.buy) # commission
          @emit 'debug', "buy total cost: #{total_cost}"

          if account.balance < total_cost
            msg = "#{username}'s balance is #{account.balance}, but cost is #{total_cost}"
            @emit 'error', 'NOT_ENOUGH_MONEY', msg
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
              expenses: total_cost
        when 'sell'
          unless order.ticker of account.portfolio
            msg = "#{username} doesn't own any #{order.ticker}"
            @emit 'error', 'NOT_IN_PORTFOLIO', msg
          else
            amount = account.portfolio[order.ticker]
            if amount < order.amount
              msg = "#{username} doesn't have enough #{order.ticker} to sell (want to sell #{order.amount}, but we have #{amount})"
              @emit 'error', 'NOT_ENOUGH_SHARES', msg
            else
              raw_earnings = amount * ticker.price
              total_earnings = raw_earnings - (raw_earnings * @commissions.sell)
              @emit 'debug', "total earnings: #{total_earnings}"
              account.portfolio[order.ticker] -= order.amount
              account.balance += total_earnings
              account.history.push
                type: order.type
                ticker: order.ticker
                amount: order.amount
                price: ticker.price
                earnings: total_earnings
        else
          msg = "unknown order type '#{order.type}'"
          @emit 'error', 'UNKNOWN_ORDER_TYPE', msg
    onComplete undefined
