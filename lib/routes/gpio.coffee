express = require "express"
Promise = require "bluebird"
GPIO = require "../gpio"
sequential = require("../util").sequential

log = require("../log").child
  subsystem: "api"
  api: "gpio"
, true

getInfo = (gpio) ->
  Promise.props
    status: "success"
    gpio: gpio
    open: GPIO.isOpen gpio
  .then (info) ->
    if info.open
      Promise.all [
        GPIO.getDirection gpio
        GPIO.getValue gpio
      ]
      .spread (direction, value) ->
        info.direction = direction
        info.value = value
        info
    else info

module.exports = _GPIO =
  create: ->
    router = express.Router()
    .get "/", @list
    .get "/open", @listOpen
    router.route "/:gpio"
    .post @open
    .delete @close
    .get @read
    .put @write
    router

  list: (req, res) ->
    res.send
      status: "success"
      gpios: GPIO.gpios

  listOpen: (req, res, next) ->
    GPIO.getOpenGPIOs()
    .then (openGPIOs) ->
      res.send
        status: "success"
        open: openGPIOs
    .catch next

  open: (req, res, next) ->
    GPIO.open req.params.gpio
    .then getInfo
    .then (info) -> res.send info
    .catch next

  close: (req, res, next) ->
    GPIO.close req.params.gpio
    .then getInfo
    .then (info) -> res.send info
    .catch next

  read: (req, res, next) ->
    getInfo req.params.gpio
    .then (info) -> res.send info
    .catch next

  write: (req, res, next) ->
    Promise.resolve()
    .then -> GPIO.setDirection req.params.gpio, req.query.direction if req.query.direction
    .then -> GPIO.setValue req.params.gpio, req.query.value if req.query.value
    .then -> getInfo req.params.gpio
    .then (info) -> res.send info
    .catch next

