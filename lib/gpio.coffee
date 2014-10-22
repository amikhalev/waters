Promise = require "bluebird"
util = require "util"
fs = Promise.promisifyAll require "fs"

log = require("./log").child subsystem: "gpio", true

SYSFS = "/sys/class/gpio"

sanitizeGPIO = (gpio) ->
  new Promise (resolve, reject) =>
    _gpio = if typeof gpio is "string" then parseInt gpio, 10 else gpio
    return reject new GPIO.GPIOError "InvalidGPIO", "GPIO #{gpio} is invalid" unless _gpio in GPIO.gpios
    resolve "#{gpio}"
sanitizeDirection = (direction) ->
  new Promise (resolve, reject) ->
    switch "#{direction}".toLowerCase()
      when "in", "input"
        resolve GPIO.IN
      when "out", "output"
        resolve GPIO.OUT
      else
        reject new GPIO.GPIOError "InvalidDirection", "Direction #{direction} in invalid"
sanitizeValue = (value) ->
  new Promise (resolve, reject) ->
    switch "#{value}".toLowerCase()
      when "true", "1"
        resolve "1"
      when "false", "0"
        resolve "0"
      else
        reject new GPIO.GPIOError "InvalidValue", "Value #{value} in invalid"
sysfsErrors = (gpio) ->
  (e) ->
    if gpio and /ENOENT/.test e.message then throw new GPIO.GPIOError "GPIONotOpen", "GPIO #{gpio} is not open"
    else if gpio and /EBUSY/.test e.message then throw new GPIO.GPIOError "GPIOAlreadyOpen", "GPIO #{gpio} is already open"
    else if /EACCES|EPERM/.test e.message then throw new GPIO.GPIOError "AccessDenied", "No permission in directory #{SYSFS}"
    else throw e

GPIO =
  open: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) =>
      log.trace
        action: "open"
        gpio: gpio
      , "Opening GPIO #{gpio}"
      fs.writeFileAsync "#{SYSFS}/export", gpio
    .catch sysfsErrors gpio
  close: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) =>
      log.trace
        action: "close"
        gpio: gpio
      , "Closing GPIO #{gpio}"
      fs.writeFileAsync "#{SYSFS}/unexport", gpio
    .catch sysfsErrors gpio
  isOpen: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) =>
      log.trace
        action: "isOpen"
        gpio: gpio
      , "Checking if GPIO #{gpio} is exported"
      filename = "#{SYSFS}/gpio#{gpio}"
      fs.existsAsync filename
    .catch sysfsErrors gpio
  getOpenGPIOs: ->
    log.trace
      action: "getOpenGPIOs"
    , "Listing open GPIOs"
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
    .spread (gpio, direction) =>
      log.trace
        action: "setDirection"
        gpio: gpio
        direction: direction
      , "Setting the direction of GPIO #{gpio} to #{direction}"
      fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/direction", direction
    .catch sysfsErrors gpio
  getDirection: (gpio) ->
    sanitizeGPIO gpio
    .then (gpio) =>
      log.trace
        action: "getDirection"
        gpio: gpio
      , "Getting the direction of GPIO #{gpio}"
      fs.readFileAsync("#{SYSFS}/gpio#{gpio}/direction")
    .then (data) ->
      data.toString().split("\n")[0]
    .catch sysfsErrors gpio
  setValue: (gpio, value) ->
    Promise.all [
      sanitizeGPIO gpio
      sanitizeValue value
    ]
    .spread (gpio, value) =>
      log.trace
        action: "setValue"
        gpio: gpio
        value: value
      , "Setting the value of GPIO #{gpio} to #{value}"
      fs.writeFileAsync "#{SYSFS}/gpio#{gpio}/value", value
    .catch sysfsErrors gpio
  getValue: (gpio, value) ->
    sanitizeGPIO gpio
    .then (gpio) =>
      log.trace
        action: "getValue"
        gpio: gpio
      , "Getting the value of GPIO #{gpio}"
      fs.readFileAsync "#{SYSFS}/gpio#{gpio}/value"
    .catch sysfsErrors gpio
    .then (data) =>
      val = /1/.test data.toString()
      if val then "1" else "0"

GPIO.IN = "in"
GPIO.OUT = "out"
GPIO.gpios = [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25]
GPIO.GPIOError = class GPIOError extends Error
  constructor: (@name, @message) ->

module.exports = GPIO
