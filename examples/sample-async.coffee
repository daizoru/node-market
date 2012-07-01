{inspect} = require 'util'
log = console.log 
{Market,Stock,Product,humanize} = require './market'
async = require 'async'
# initialize a new Market
# you can create future, commodity, stock or forex markets


market = new Market

  # some meta data
  name: "Programming Languaghe Exchange"
  symbol: "PLE"

  # now we add some traded objects, uniquely identified by a shortname
  products:

    JS: new Stock
      name: "JavaScript"
      symbol: "JS"
      volume: 30000
      price: 31.30

    RB: new Stock
      name: "Ruby"
      symbol: "RB"
      volume: 30000
      price: 31.30

    PY: new Stock
      name: "Python"
      symbol: "PY"
      volume: 30000
      price: 30.00

# you can put either use Market in a single app,
# or behind a server
# in the first case, you will directly manipulate the market
# (eg. to issue arbitrary orders, add stocks..), and open user sessions

# in the future I might create
# node-market-server and node-market-client
# the first would simply host a node-market instance

# for the moment there is no persistence so we need
# to re-create our account each time
market.createAccount "john", "JohnDoe", 5000 # $

# let's open the market!
market.open()

# here, we choose to create some "generic" workflow steps,
# and use async.js. b
# ut you are free to implement or use any other async/futures paradigm!
login = (username, password) -> 
  (pass) ->
    market.login username, password, (notice, session) ->
      if notice
        pass "login failed (#{notice})"
      else
        log "connected to market as #{username}"
        pass null, session

buy = (symbol, volume) -> 
  (session, pass) ->
    session.buy symbol, volume, (notice) ->
      if notice
        pass "buying failed (#{notice})"
      else
        log "bought: #{volume} shares of #{symbol}"
        pass null, session

sell = (symbol, volume) -> 
  (session, pass) ->
    session.buy symbol, volume, (notice) ->
      if notice
        pass "selling failed (#{notice})"
      else
        log "sold: #{volume} shares of #{symbol}"
        pass null, session

balance =  (session, pass) ->
  session.balance (notice, balance) ->
    # or we could just do "pass notice, session, balance"
    if notice
      pass "getting balance failed (#{notice})"
    else
      log "balance: #{humanize balance}"
      pass null, session

# our workflow
workflow = [
  login "John", "JohnDoe"
  buy "JS", 50
  balance
  buy "PY", 50 # easy to disable a workflow step
  balance
  sell "JS", 50
  balance
]


# run the workflow using async.js
async.waterfall workflow, (err, result) ->
  if err
    log "error: #{err}"
  else
    log "program terminated"
  process.exit()


