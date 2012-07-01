{inspect} = require 'util'
log = console.log 
{Market,Stock,humanize} = require './market'

NSE = new Market

  # some meta data
  name: "Node Stock Exchange"
  symbol: "NSE"

  # now we add some traded objects, uniquely identified by a shortname
  products:

    JS: new Stock
      name: "JavaScript"
      code: "JS"
      volume: 30000
      price: 31.30

    RB: new Stock
      name: "Ruby"
      code: "JS"
      volume: 30000
      price: 31.30

    PY: new Stock
      name: "Python"
      code: "PY"
      volume: 30000
      price: 30.00

NSE.createAccount "john", "JohnDoe", 5000 # $
NSE.open()

require('zappa') ->
  @enable 'serve jquery'
  
  @get '/': ->
    @render index: {layout: no, title: 'NSE'}

  @get '/admin/market/open': ->
    NSE.open()

  @get '/admin/market/close': ->
    NSE.close()

  @on login: ->
    @client.username = @data.username
    @client.session = NSE.login @data.username, @data.password

  @on buy: ->
    @client.session.buy @client.code, @client.volume, =>
      @broadcast bought: {username: @client.username, symbol: @data.symbol, volume: @data.volume}
      @emit bought: {username: @client.username, symbol: @data.symbol, volume: @data.volume}
  
  @on sell: ->
    @client.session.sell @client.code, @client.volume, =>
      @broadcast sold: {username: @client.username, symbol: @data.symbol, volume: @data.volume}
      @emit sold: {username: @client.username, symbol: @data.symbol, volume: @data.volume}
  
  @client '/index.js': ->
    @connect()

    @on bought: ->
      $('#panel').append "<p>#{@data.username} bought #{@data.volume} #{humanize @data.symbol}</p>"
    
    @on sold: ->
      $('#panel').append "<p>#{@data.username} sold #{@data.volume} #{humanize @data.symbol}</p>"
    
    $ =>
      @emit 'login':
        username: prompt 'Username'
        password: prmpt 'Password'
      
      $('#order').focus()
      
      $('button').click (e) =>
        @emit buy: {text: $('#order').val()}
        $('#order').val('').focus()
        e.preventDefault()

      #$('button').click (e) =>
      #  @emit sell: {text: $('#order').val()}
      #  $('#order').val('').focus()
      #  e.preventDefault()
    
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'Node Stock Exchange'
        script src: '/socket.io/socket.io.js'
        script src: '/zappa/jquery.js'
        script src: '/zappa/zappa.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'symbol'
          input id: 'volume'
          button 'Buy'
          button 'Sell'

