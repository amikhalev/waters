express = require "express"
bunyan = require "bunyan"
config = require "./config/"
log = require "./log"

module.exports = ->
  httpLog = log.child subsystem: "http", true

  routes = require("./routes/")

  app = express()

  app.use require("express-bunyan-logger")()

  app.use "/api/gpios", routes.gpio.create()
  routes.section.bind app, "/api/sections"
  routes.program.bind app, "/api/programs"

  app.use (err, req, res, next) ->
    status = err.status or 500
    res.status(status).json
      status: "error"
      name: err.name
      message: err.message
      stack: err.stack if status is 500

  port = config.server.port
  server = app.listen port, ->
    addr = server.address()
    log.info "waters listening at %s:%s", addr.host, addr.port
