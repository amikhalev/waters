Promise = require "bluebird"
util = require "util"
fs = Promise.promisifyAll require "fs"
APIError = require("./errors").APIError

log = require("./log").child subsystem: "gpio", true

SYSFS = "/sys/class/gpio"

sanitizeGPIO = (gpio) ->
  if typeof gpio is "string" then gpio = parseInt gpio, 10
  if gpio in GPIO.gpios
    Promise.resolve "#{gpio}"
  else
    Promise.reject new GPIO.GPIOError "InvalidGPIOError", "Invalid GPIO #{gpio}"
sanitizeDirection = (direction) ->
  switch "#{direction}".toLowerCase()
    when "in", "input"
      Promise.resolve GPIO.IN
    when "out", "output"
      Promise.resolve GPIO.OUT
    else
      Promise.reject new GPIO.GPIOError "InvalidDirectionError", "Invalid direction #{direction}"
sanitizeValue = (value) ->
  switch "#{value}".toLowerCase()
    when "true", "1"
      Promise.resolve "1"
    when "false", "0"
      Promise.resolve "0"
    else
      Promise.reject new GPIO.GPIOError "InvalidValueError", "Invalid value #{value}"
sysfsErrors = (gpio) ->
  (e) ->
    if gpio and /ENOENT/.test e.message
      throw new GPIO.GPIOError "GPIONotOpenError", "GPIO #{gpio} is not open"
    else if gpio and /EBUSY/.test e.message
      throw new GPIO.GPIOError "GPIOAlreadyOpenError", "GPIO #{gpio} is already open"
    else if /EACCES|EPERM/.test e.message
      throw new GPIO.GPIOError "AccessDeniedError", "No permission in directory #{SYSFS}", 500
    else throw e

GPIO =
  IN: "in"
  OUT: "out"
  gpios: [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25]

  GPIOError: class GPIOError extends APIError
    constructor: (name, message, status) ->
      super name, message, status or 400

  stub: ->
    log.warn "Stubbing gpio methods"
    _gpios = @gpios.reduce (_gpios, gpio) ->
      _gpios["#{gpio}"] =
        open: false
        direction: "in"
        value: false
      _gpios
    , {}

    @open = (gpio) ->
      log.error gpio
      log.trace
        action: "open"
        gpio: gpio
      , "[STUB] open #{gpio}"
      sanitizeGPIO gpio
      .then (gpio) -> _gpios[gpio].open = true

    @close = (gpio) ->
      log.trace
        action: "close"
        gpio: gpio
      , "[STUB] close #{gpio}"
      sanitizeGPIO gpio
      .then (gpio) -> _gpios[gpio].open = false

    @isOpen = (gpio) ->
      log.trace
        action: "isOpen"
        gpio: gpio
      , "[STUB] isOpen #{gpio}"
      sanitizeGPIO gpio
      .then (gpio) -> _gpios[gpio].open

    @getOpenGPIOs = ->
      log.trace
        action: "getOpenGPIOs"
      , "[STUB] getOpenGPIOs"
      Promise.resolve
      Object.keys _gpios
      .filter (gpio) -> not _gpios[gpio].open

    @setDirection = (gpio, direction) ->
      log.trace
        action: "setDirection"
        gpio: gpio
        direction: direction
      , "[STUB] setDirection #{gpio}, #{direction}"
      Promise.all [
        sanitizeGPIO gpio
        sanitizeDirection direction
      ]
      .spread (gpio, direction) -> _gpios[gpio].direction = direction

    @getDirection = (gpio) ->
      log.trace
        action: "getDirection"
        gpio: gpio
      , "[STUB] getDirection #{gpio}"
      sanitizeGPIO gpio
      .then (gpio) -> _gpios[gpio].direction

    @setValue = (gpio, value) ->
      log.trace
        action: "setValue"
        gpio: gpio
        value: value
      , "[STUB] setValue #{gpio}, #{value}"
      Promise.all [
        sanitizeGPIO gpio
        sanitizeValue value
      ]
      .spread (gpio, value) -> _gpios[gpio].value = value

    @getValue = (gpio) ->
      log.trace
        action: "getValue"
        gpio: gpio
      , "[STUB] getValue #{gpio}"
      sanitizeGPIO gpio
      .then (gpio) -> _gpios[gpio].value

  open: (gpio) ->
    log.trace
      action: "open"
      gpio: gpio
    , "open #{gpio}"
    sanitizeGPIO gpio
    .then (gpio) -> fs.writeFileAsync "#{SYSFS}/export", gpio
    .catch sysfsErrors gpio

  close: (gpio) ->
    log.trace
      action: "close"
      gpio: gpio
    , "close #{gpio}"
    sanitizeGPIO gpio
    .then (gpio) -> fs.writeFileAsync "#{SYSFS}/unexport", gpio
    .catch sysfsErrors gpio

  isOpen: (gpio) ->
    log.trace
      action: "isOpen"
      gpio: gpio
    , "isOpen #{gpio}"
    sanitizeGPIO gpio
    .then (gpio) -> fs.existsAsync "#{SYSFS}/gpio#{gpio}"
    .catch sysfsErrors gpio

  getOpenGPIOs: ->
    log.trace
      action: "getOpenGPIOs"
    , "getOpenGPIOs"
    fs.readdirAsync(SYSFS)
    .filter (file) -> not /export|gpiochip/.test file
    .map (file) -> parseInt file.substr(4), 10 # in the format gpioNN
    .catch sysfsErrors()

  setDirection: (gpio, direction) ->
    log.trace
      action: "setDirection"
      gpio: gpio
      direction: direction
    , "setDirection #{gpio}, #{direction}"
    Promise.all [
      sanitizeGPIO gpio
      sanitizeDirection direction
    ]
    .spread (gpio, direction) -> fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/direction", direction
    .catch sysfsErrors gpio

  getDirection: (gpio) ->
    log.trace
      action: "getDirection"
      gpio: gpio
    , "getDirection #{gpio}"
    sanitizeGPIO gpio
    .then (gpio) -> fs.readFileAsync("#{SYSFS}/gpio#{gpio}/direction")
    .then (data) -> data.toString().split("\n")[0]
    .catch sysfsErrors gpio

  setValue: (gpio, value) ->
    log.trace
      action: "setValue"
      gpio: gpio
      value: value
    , "setValue #{gpio}, #{value}"
    Promise.all [
      sanitizeGPIO gpio
      sanitizeValue value
    ]
    .spread (gpio, value) -> fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/value", value
    .catch sysfsErrors gpio

  getValue: (gpio) ->
    log.trace
      action: "getValue"
      gpio: gpio
    , "getValue #{gpio}"
    sanitizeGPIO gpio
    .then (gpio) -> fs.readFileAsync "#{SYSFS}/gpio#{gpio}/value"
    .catch sysfsErrors gpio
    .then (data) -> /1/.test data.toString() ? "1" : "0"

module.exports = GPIO
