GPIO = require "../gpio"
restify = require "restify"

log = require("../log").child
  subsystem: "api"
  api: "gpio"
, true

module.exports = _GPIO =
  bind: (server, base) ->
    server.get "#{base}/list", @list
    server.get "#{base}/open", @listOpen
    server.post "#{base}/:gpio/", @open
    server.del "#{base}/:gpio/", @close
    server.get "#{base}/:gpio/direction", @getDirection
    server.put "#{base}/:gpio/direction", @setDirection
    server.get "#{base}/:gpio/value", @getValue
    server.put "#{base}/:gpio/value", @setValue

  list: (req, res, next) ->
    res.send GPIO.gpios
    next()

  listOpen: (req, res, next) ->
    GPIO.getOpenGPIOs()
    .then (openGPIOs) ->
      res.send openGPIOs
      next()
    , (err) ->
      res.send new APIError err
      next()

  open: (req, res, next) ->
    GPIO.open req.params.gpio
    .then ->
      res.send()
      next()
    , (err) ->
      res.send new APIError err
      next()

  close: (req, res, next) ->
    GPIO.close req.params.gpio
    .then ->
      res.send()
      next()
    , (err) ->
      res.send new APIError err
      next()

  getDirection: (req, res, next) ->
    GPIO.getDirection req.params.gpio
    .then (direction) ->
      res.send direction
      next()
    , (err) ->
      res.send new APIError err
      next()

  setDirection: (req, res, next) ->
    GPIO.setDirection req.params.gpio, req.params.direction
    .then ->
      res.send req.params.direction
      next()
    , (err) ->
      res.send new APIError err
      next()

  getValue: (req, res, next) ->
    GPIO.getValue req.params.gpio
    .then (value) ->
      res.send value
      next()
    , (err) ->
      res.send new APIError err
      next()

  setValue: (req, res, next) ->
    GPIO.setValue req.params.gpio, req.params.value
    .then ->
      res.send req.params.value
      next()
    , (err) ->
      res.send new APIError err
      next()

class APIError extends restify.RestError
  constructor: (err) ->
    super
      restCode: err.name
      statusCode: if err instanceof GPIO.GPIOError then 400 else 500
      message: err.message
      constructorOpt: APIError
    @name = err.name

