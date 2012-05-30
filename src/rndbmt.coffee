module.exports = ->
  x = 0
  y = 0
  rds = 0
  loop
    x = Math.random() * 2 - 1
    y = Math.random() * 2 - 1
    rds = x * x + y * y
    break unless rds is 0 or rds > 1
  c = Math.sqrt(-2 * Math.log(rds) / rds)
  [ x * c, y * c ]


