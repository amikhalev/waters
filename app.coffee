require("source-map-support").install()

Promise = require "bluebird"
GPIO = require "./lib/gpio"

Promise.longStackTraces()
GPIO.stub()

require("./lib/sequelize")()
.then require "./lib/express"
