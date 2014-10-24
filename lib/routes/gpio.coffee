restify = require "restify"
GPIO = require "../gpio"
RestError = require("../errors").RestError

log = require("../log").child
  subsystem: "api"
  api: "gpio"
, true

module.exports = _GPIO =
  bind: (server, base) ->
    server.get "#{base}", @list
    server.get "#{base}/open", @listOpen
    server.post "#{base}/:gpio", @open
    server.del "#{base}/:gpio", @close
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
    , (err) ->
      res.send new RestError err
    .finally -> next();

  open: (req, res, next) ->
    GPIO.open req.params.gpio
    .then ->
      res.send()
    , (err) ->
      res.send new RestError err
    .finally -> next();

  close: (req, res, next) ->
    GPIO.close req.params.gpio
    .then ->
      res.send()
    , (err) ->
      res.send new RestError err
    .finally -> next();

  getDirection: (req, res, next) ->
    GPIO.getDirection req.params.gpio
    .then (direction) ->
      res.send direction
    , (err) ->
      res.send new RestError err
    .finally -> next();

  setDirection: (req, res, next) ->
    GPIO.setDirection req.params.gpio, req.params.direction
    .then ->
      res.send req.params.direction
    , (err) ->
      res.send new RestError err
    .finally -> next();

  getValue: (req, res, next) ->
    GPIO.getValue req.params.gpio
    .then (value) ->
      res.send value
    , (err) ->
      res.send new RestError err
    .finally -> next();

  setValue: (req, res, next) ->
    GPIO.setValue req.params.gpio, req.params.value
    .then ->
      res.send req.params.value
    , (err) ->
      res.send new RestError err
    .finally -> next();

