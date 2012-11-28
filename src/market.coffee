{inspect} = require 'util'
Stream    = require 'stream'

{delay}   = require 'ragtime'
geekdaq   = require 'geekdaq'

pretty = (obj) -> "#{inspect obj}"

randInt = (min,max) -> Math.round(min + Math.random() * (max - min))

class module.exports extends Stream

  constructor: (options={}) ->
    @server         = options.server         ? 'geekdaq'
    @codes          = options.tickers        ? []
    @updateInterval = options.updateInterval ? 500
    @commissions    = options.commissions    ? {buy: 0, sell: 0}
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

  ticker: (code) => 
    @tickers[code]

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


  execute: (username, orders) =>
    account = @accounts[username]
    @emit 'debug', "username: #{username} and account: #{pretty account}"
    for order in orders
      @emit 'debug', "processing #{order.type} order:"
      ticker = @ticker order.ticker
      switch order.type
        when 'buy'
          raw_cost = order.amount * ticker.price
          #puts "raw cost: #{raw_cost}"
          total_cost = raw_cost + (raw_cost * @commissions.buy) # commission
          @emit 'debug', "buy total cost: #{total_cost}"

          if account.balance < total_cost
            @emit 'error', 'NOT_ENOUGH_MONEY', "#{username}'s balance is #{account.balance}, but cost is #{total_cost}"
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
            @emit 'error', 'NOT_IN_PORTFOLIO', "#{username} doesn't own any #{order.ticker}"
            # for now, just let go
            #throw new Error "invalid order: we do not own any #{order.ticker}"
            return
          amount = account.portfolio[order.ticker]
          if amount < order.amount
            @emit 'error', 'NOT_ENOUGH_SHARES', "#{username} doesn't have enough #{order.ticker} to sell (want to sell #{order.amount}, but we have #{amount})"
            return
          raw_benefits = amount * ticker.price
          #log "raw benefits: #{raw_benefits}"
          total_benefits = raw_benefits - (raw_benefits * @commissions.sell) # commission
          @emit 'debug', "total benefits: #{total_benefits}"
          account.portfolio[order.ticker] -= order.amount
          account.balance += total_benefits
          account.history.push
            type: order.type
            ticker: order.symbol
            amount: order.amount
            price: ticker.price
            total_benefit: total_benefits
