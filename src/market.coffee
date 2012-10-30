# a virtual market
# it is very, very crude and minimalist
# you can only buy and sell toy shares,
# at market price. Very basic stuff,
# but it should be funny to play with.

{inspect} = require 'util'
log = console.log

crypto = require 'crypto'
{delay} = require 'ragtime'
penny = require 'penny'
timmy = require 'timmy'

UNIT = 1000
humanize = (value) -> "$#{Math.round(value)/UNIT}"

# min and max will be included
randfloat = exports.randfloat = (max,min=0) -> Math.random() * ((max)-min) + min

# min and max will be included
randint = exports.randint = (max,min=0) -> Math.floor(Math.random() * ((max+1)-min)) + min

P = exports.P = (p=0.5) -> + (Math.random() < p) # TODO check if the + () is not removed by optimizers


class Session
  ###
  A simple user session. managed by the server
  ###
  constructor: (@market, @passphrase, @username, @hashedPassword) ->
    
  buy: (symbol, volume, onComplete) ->
    query = session: @passphrase, cb: onComplete
    @market.buy query, symbol, volume
  sell: (symbol, volume, onComplete) ->
    query = session: @passphrase, cb: onComplete
    @market.sell query, symbol, volume
  balance: (onComplete) ->
    query = session: @passphrase, cb: onComplete
    @market.balance query
  quote: (symbol, onComplete) ->
    query = session: @passphrase, cb: onComplete
    @market.quote query, symbol
  logout: (onComplete) ->
    query = session: @passphrase, cb: onComplete
    @market.logout query

class Product
  constructor: (args={}) ->
    @name = if args.name? then args.name else ""
    @symbol = if args.symbol? then args.symbol.toUpperCase() else @name.toUpperCase()
    @volume = if args.volume? then args.volume else 0
    @price =  if args.price? then (args.price * UNIT) else 1

    @market = no


class Security
  constructor: (args={}) ->
    @market = no
    @name = if args.name? then args.name else ""
    @symbol = if args.symbol? then args.symbol.toUpperCase() else @name.toUpperCase()
    @volume = if args.volume? then args.volume else 0
    @price =  if args.price? then (args.price * UNIT) else 1


class Stock extends Security
  constructor: (args={}) ->
    super args

    # stock-related attributes
    #equityState

class Bond extends Security
  constructor: (args={}) ->
    super args

    # stock-related attributes
    #equityState

    # the holder of the bond is the lender (creditor)
    @holder = ""

    # the issuer of the bond is the borrower (debtor)
    @issuer = ""

    ### Coupon

     the interest rate that the issuer pays to the bond holders.

     Usually this rate is fixed throughout the life of the bond.
     It can also vary with a money market index, such as LIBOR,
     or it can be even more exotic. The name coupon originates
     from the fact that in the past, physical bonds were issued
     which had coupons attached to them. On coupon dates the
     bond holder would give the coupon to a bank in exchange
     for the interest payment. Coupons can be paid at different
     frequencies. It is generally semi-annual or annual.
    ###
    @coupon = 0


    ### Maturity

    the date on which the issuer has to repay the nominal amount. 

    As long as all payments have been made, the issuer has no more 
    obligation to the bond holders after the maturity date. The 
    length of time until the maturity date is often referred to as
    the term or tenor or maturity of a bond. The maturity can be
    any length of time, although debt securities with a term of
    less than one year are generally designated money market
    instruments rather than bonds. Most bonds have a term of up to
    thirty years. Some bonds have been issued with maturities of
    up to one hundred years, and some do not mature at all. In the
    market for U.S. Treasury securities, there are three groups of
    bond maturities:
      - short term (bills): maturities between one to five year; 
        (instruments with maturities less than one year are called
        Money Market Instruments)
      - medium term (notes): maturities between six to twelve years;
      - long term (bonds): maturities greater than twelve years.

    source: Wikipedia
    link: http://en.wikipedia.org/wiki/Bond_(finance)
    ###
    @maturity = 0

    @quality = no

    @optionality = no


# a minimalist market, for one broker, one user,
# using historic data or real thing. for test purposes.
class Market
  constructor: (args={}) ->
    @name = if args.name? then args.name else "Market"
    @symbol = if args.symbol? then args.symbol else "MARK"

    @products = {}
    if args.products
      for symbol,product of args.products
        product.market = @
        @products[symbol] = product
    @accounts = {}
    if args.products
      for login,account of args.accounts
        @createAccount login, account.password, account.balance
    @sessions = {}

    @runMarket = no
    @model = 
      cycles: 0
      tendency: 0.5
    # TODO replace by buy/sell orders
    @model.priceVariation = => 
      if @model.cycles++ >= 10
        @model.cycles = 0
        @model.tendency = 0.5 - Math.random() # + or -
      res = Math.random() * 200
      res *= @model.tendency
      res

  hash: (txt) ->
   crypto.createHmac('sha1', "randomsalt").update(txt).digest('hex')

  open: ->
    # send messages to brokers
    @runMarket = yes
    @updateQuotes()
    #log "market is open"
  close: ->
    @runMarket = no
    #log "market is closed"

  createAccount: (username, password, balance = eur(0)) ->
    username = username.toLowerCase()
    log "creating account #{username}, password #{password}, balance #{balance}"
    if username of @accounts
      throw "user #{username} already exists"
      return

    @accounts[username] =
      username: username
      password: @hash password
      balance: balance.multiply UNIT
      stocks: {}

  logout: (query) ->
    account = @validate query
    return query.refuse 'invalid session' unless account
    delete @sessions[query.Session]
    query.reply()

  validate: (query) ->
    query.refuse = (err='') ->
      #console.log "refusing query"
      delay 0, -> 
        query.cb err, 0
      return
    query.reply = (value='') ->
      #console.log "accepting query"
      delay 0, -> 
        query.cb '', value
      return

    # check if we are valid session
    session = @sessions[query.session]
    if session
      account = @accounts[session.username]
      return account
    else
      return no

  # a stupid function, that should be replaced
  updateQuotes: =>
    return unless @runMarket
    #console.log "updating quotes"
   
    for symbol, volume of @products
      old = @products[symbol].price
      @products[symbol].price += @model.priceVariation()
      #log "#{symbol} #{humanize old} -> #{humanize @products[symbol].price}"
    #console.log "updated quotes"
    delay 1000, =>
      @updateQuotes()
  
  login: (username, password, onComplete) =>
    username = username.toLowerCase()
    #log "trying to login using username: '#{username}' and password: '#{password}'"
    unless username of @accounts
      throw "Unknow user \"#{username}\""
      return
    account = @accounts[username]
    hashedPassword = @hash password
    unless hashedPassword is account.password
      throw "Error, invalid password. Hacking is a crime. Try again and you will face prosecution"
      return
    sessionPassphrase = "#{username}:#{hashedPassword}:salt"
    #log "created session passphrase. now initializing new Session"
    session = new Session @, sessionPassphrase, username, hashedPassword
    @sessions[sessionPassphrase] = session
    #console.dir @sessions

    # fake a standard login procedure
    query =
      session: session
      cb: onComplete
    account = @validate query
    query.reply query.session

  quote: (query, symbol) ->
    account = @validate query
    return query.refuse 'invalid session' unless account
    #log "symbol: #{symbol} @products: #{inspect @products}"
    stock = @products[symbol]
    return query.refuse "unknow symbol #{symbol}" unless stock
    query.reply stock.price
      
  # TODO should be added to a list of orders
  buy: (query, symbol, volume) ->
    account = @validate query
    return query.refuse 'invalid session' unless account

    symbol = symbol.toUpperCase()
    if symbol of @products
      stock = @products[symbol]
      if volume <= stock.volume
        existingPrice = stock.price
        futurePrice = existingPrice + existingPrice * ( volume / stock.volume )
        #log "futurePrice: " + humanize futurePrice
        averagePrice = (existingPrice + futurePrice) / 2
        cost = averagePrice * volume
        commission = @commission cost
        #log "commission: " + humanize commission
        cost += commission
        #log "estimatedCost: " + humanize estimatedCost
        if account.balance >= cost
          # TRANSACTION ON
          account.balance -= cost
          #log "account.balance: " + humanize account.balance
          @products[symbol].price = futurePrice

          account.stocks[symbol] = {volume: 0} unless symbol of account.stocks
          account.stocks[symbol].volume += volume
          @products[symbol].volume -= volume
          query.reply()
        else
          query.refuse "for some reason"
          # TRANSACTION OFF
      else
        query.refuse "you don't have enough shares to sell"
    else
      query.refuse "symbol #{symbol} not found"

  # TODO should be added to a list of orders
  sell: (query, symbol, volume) ->
    account = @validate query
    return query.refuse 'invalid session' unless account

    symbol = symbol.toUpperCase()
    if symbol of @products
      #console.log "symbol of stocks"
      stock = @products[symbol]
      return query.refuse "user don't own any share of #{symbol}" unless symbol of account.stocks

      #console.log "account.stocks[symbol]: #{inspect account.stocks[symbol]}"
      #console.log "volume: #{volume}; account.stocks[symbol].volume: #{account.stocks[symbol].volume}"
      if volume <= account.stocks[symbol].volume
        #console.log "we can sell"
        existingPrice = stock.price
        futurePrice = existingPrice - existingPrice * ( volume / stock.volume )
        averagePrice = (existingPrice + futurePrice) / 2
        earnings = averagePrice * volume
        commission = @commission earnings
        #log "commission: " + humanize commission
        earnings -= commission
        #log "estimatedBenefit: " + humanize estimatedBenefit

        # let's suppose we can always sell at any price
        if on
          # TRANSACTION ON
          account.balance += earnings
          @products[symbol].price = futurePrice
          
          #account.stocks[symbol].volume = 0
          account.stocks[symbol].volume -= volume
          @products[symbol].volume += volume
          query.reply()
        else
          query.refuse "for some reason"
        # TRANSACTION OFF
      else
        query.refuse "no more stocks on the market to buy, please wait"

    else
      query.refuse "symbol #{symbol} not found"

  balance: (query) -> 
    account = @validate query
    return query.refuse 'invalid session' unless account
    query.reply account.balance

  commission: (order) ->
    category = "A"
    #console.log "order: " + humanize order
    switch category
      when "A"
        if order <= 500000
          1990
        else
          order * 0.006
      when "B"
        if order <= 1000000
          5500
        else
          estimated = order * 0.0048
          estimated = 8950 if estimated < 8950
          estimated
      when "C"
        if order <= 7750000
          16650
        else
          order * 0.0022
      when "D"
        if order <= 10000000
          9900
        else
          order * 0.0012
      else
        0

exports.Market = Market
exports.Session = Session
exports.Stock = Stock
exports.humanize = humanize
exports.Product = Product
