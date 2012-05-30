// Generated by CoffeeScript 1.3.3
(function() {
  var Market, Stock, async, balance, buy, humanize, inspect, log, login, market, sell, workflow, _ref;

  inspect = require('util').inspect;

  log = console.log;

  _ref = require('./market'), Market = _ref.Market, Stock = _ref.Stock, humanize = _ref.humanize;

  async = require('async');

  market = new Market({
    name: "Node Stock Exchange",
    symbol: "NSE",
    products: {
      JS: new Stock({
        name: "JavaScript",
        symbol: "JS",
        volume: 30000,
        price: 31.30
      }),
      RB: new Stock({
        name: "Ruby",
        symbol: "JS",
        volume: 30000,
        price: 31.30
      }),
      PY: new Stock({
        name: "Python",
        symbol: "PY",
        volume: 30000,
        price: 30.00
      })
    }
  });

  market.createAccount("john", "JohnDoe", 5000);

  market.open();

  login = function(username, password) {
    return function(pass) {
      return market.login(username, password, function(notice, session) {
        if (notice) {
          return pass("login failed (" + notice + ")");
        } else {
          log("connected to market as " + username);
          return pass(null, session);
        }
      });
    };
  };

  buy = function(symbol, volume) {
    return function(session, pass) {
      return session.buy(symbol, volume, function(notice) {
        if (notice) {
          return pass("buying failed (" + notice + ")");
        } else {
          log("bought: " + volume + " shares of " + symbol);
          return pass(null, session);
        }
      });
    };
  };

  sell = function(symbol, volume) {
    return function(session, pass) {
      return session.buy(symbol, volume, function(notice) {
        if (notice) {
          return pass("selling failed (" + notice + ")");
        } else {
          log("sold: " + volume + " shares of " + symbol);
          return pass(null, session);
        }
      });
    };
  };

  balance = function(session, pass) {
    return session.balance(function(notice, balance) {
      if (notice) {
        return pass("getting balance failed (" + notice + ")");
      } else {
        log("balance: " + (humanize(balance)));
        return pass(null, session);
      }
    });
  };

  workflow = [login("John", "JohnDoe"), buy("JS", 50), balance, buy("PY", 50), balance, sell("JS", 50), balance];

  async.waterfall(workflow, function(err, result) {
    if (err) {
      log("error: " + err);
    } else {
      log("program terminated");
    }
    return process.exit();
  });

}).call(this);