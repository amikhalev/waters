Promise = require "bluebird"
util = require "util"
fs = Promise.promisifyAll require "fs"
APIError = require("./errors").APIError

log = require("./log").child subsystem: "gpio", true

SYSFS = "/sys/class/gpio"

sanitizeGPIO = (gpio) ->
  _gpio = if typeof gpio is "string" then parseInt gpio, 10 else gpio
  if _gpio in GPIO.gpios
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
    @open = (gpio) ->
      log.trace "[STUB] open #{gpio}"
      Promise.resolve()
    @close = (gpio) ->
      log.trace "[STUB] close #{gpio}"
      Promise.resolve()
    @isOpen = (gpio) ->
      log.trace "[STUB] isOpen #{gpio}"
      Promise.resolve true
    @setDirection = (gpio, direction) ->
      log.trace "[STUB] setDirection #{gpio}, #{direction}"
      Promise.resolve()
    @getDirection = (gpio) ->
      log.trace "[STUB] getDirection #{gpio}"
      Promise.resolve GPIO.OUT
    @setValue = (gpio, value) ->
      log.trace "[STUB] setValue #{gpio}, #{value}"
      Promise.resolve()
    @getValue = (gpio) ->
      log.trace "[STUB] getValue #{gpio}"
      Promise.resolve true

  open: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) ->
      log.trace
        action: "open"
        gpio: gpio
      , "open #{gpio}"
      fs.writeFileAsync "#{SYSFS}/export", gpio
    .catch sysfsErrors gpio

  close: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) ->
      log.trace
        action: "close"
        gpio: gpio
      , "close #{gpio}"
      fs.writeFileAsync "#{SYSFS}/unexport", gpio
    .catch sysfsErrors gpio

  isOpen: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) ->
      log.trace
        action: "isOpen"
        gpio: gpio
      , "isOpen #{gpio}"
      filename = "#{SYSFS}/gpio#{gpio}"
      fs.existsAsync filename
    .catch sysfsErrors gpio

  getOpenGPIOs: ->
    log.trace
      action: "getOpenGPIOs"
    , "getOpenGPIOs"
    fs.readdirAsync(SYSFS)
    .filter (file) ->
      not /export|gpiochip/.test file
    .map (file) ->
      parseInt file.substr(4), 10 # in the format gpioNN
    .catch sysfsErrors()

  setDirection: (gpio, direction) ->
    Promise.all [
      sanitizeGPIO gpio
      sanitizeDirection direction
    ]
    .spread (gpio, direction) ->
      log.trace
        action: "setDirection"
        gpio: gpio
        direction: direction
      , "setDirection #{gpio}, #{direction}"
      fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/direction", direction
    .catch sysfsErrors gpio

  getDirection: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) ->
      log.trace
        action: "getDirection"
        gpio: gpio
      , "getDirection #{gpio}"
      fs.readFileAsync("#{SYSFS}/gpio#{gpio}/direction")
    .then (data) ->
      data.toString().split("\n")[0]
    .catch sysfsErrors gpio

  setValue: (gpio, value) ->
    Promise.all [
      sanitizeGPIO gpio
      sanitizeValue value
    ]
    .spread (gpio, value) ->
      log.trace
        action: "setValue"
        gpio: gpio
        value: value
      , "setValue #{gpio}, #{value}"
      fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/value", value
    .catch sysfsErrors gpio

  getValue: (gpio, value) ->
    sanitizeGPIO gpio
    .then (gpio) ->
      log.trace
        action: "getValue"
        gpio: gpio
      , "getValue #{gpio}"
      fs.readFileAsync "#{SYSFS}/gpio#{gpio}/value"
    .catch sysfsErrors gpio
    .then (data) ->
      val = /1/.test data.toString()
      if val then "1" else "0"

module.exports = GPIO
