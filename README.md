node-market
===========

## Description

This is a market simulator for products. These can be apples and tomatoes, or more advanced things like commodities and bonds.
The goal is to have something modular enough to be used for a variety of purposes (games, simulations, research, fun..)

For the moment, it is very basic and crude. Nothing really work. Stay tuned

## TODO

Everything, tests, use cases.. code, too.

## Example

```coffeescript
{Market,Stock} = require './market'

market = new Market

  # some meta data
  name: "Programming Language Exchange"
  symbol: "PLE"

  # now we add some traded objects, uniquely identified by a shortname
  products:

    JS: new Stock
      name: "JavaScript"
      symbol: "JS"
      volume: 30000
      price: 21.30

    RB: new Stock
      name: "Ruby"
      symbol: "RB"
      volume: 30000
      price: 42.00

    PY: new Stock
      name: "Python"
      symbol: "PY"
      volume: 30000
      price: 30.00

    

market.createAccount "john", "JohnDoe", 1000 # 1000 bucks
market.open()

market.login "john", "JohnDoe", (notice, session) ->
  if notice
    throw "login failed (#{notice})"
    return
  log "connected"
  session.buy "JS", 15, (notice) ->
    if notice
      throw "failed to buy JavaScript: (#{notice})"
      return
    log "just bought 15 shared of JS"

```

