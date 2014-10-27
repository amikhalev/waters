Promise = require "bluebird"
GPIO = require "../gpio"
errors = require "../errors"
APIError = errors.APIError

log = require("../log").child
  subsystem: "models"
  model: "Section"
, true

module.exports = (sequelize, DataTypes) ->
  Section = sequelize.define 'Section',
    name:
      type: DataTypes.STRING()
      allowNull: false
    description: type: DataTypes.STRING()
    gpio:
      type: DataTypes.INTEGER()
      allowNull: false
      validate:
        isIn:
          args: [GPIO.gpios]
          msg: "Must be a gpio pin"
    enabled:
      type: DataTypes.BOOLEAN
  ,
    instanceMethods:
      init: ->
        log.trace
          action: "init"
          id: @id
        , "init section #{@name}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if @initialized then Promise.reject new APIError "AlreadyInitializedError", "Section already initialized"
        else
          GPIO.open @gpio
          .bind this
          .then -> GPIO.setDirection @gpio, GPIO.OUT
          .then -> GPIO.setValue @gpio, false
          .tap => @initialized = true; log.error Object.keys this, "4"
      deinit: ->
        log.trace
          action: "deinit"
          id: @id
        , "deinit section #{@name}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if not @initialized then Promise.reject new APIError "NotInitializedError", "Section not initialized"
        else
          GPIO.setValue @gpio, false
          .bind this
          .then -> GPIO.close @gpio
          .tap => @initialized = false; log.error "1"
      setGPIO: (gpio) ->
        if @enabled and @initialized
          @deinit()
          .bind this
          .then -> @gpio = gpio
          .then -> @init()
          .catch (e) -> log.error e, "Error changing gpio on section #{@id}"
        else @setDataValue "gpio", gpio
      setValue: (value) ->
        log.trace
          action: "setValue"
          id: @id
        , "setValue section #{@name}"
        log.error Object.keys this, "10"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if not @initialized then Promise.reject new APIError "NotInitializedError", "Section not initialized"
        else
          GPIO.setValue @gpio, value
      runFor: (time) ->
        log.trace
          action: "runFor"
          runTime: time
          id: @id
        , "runFor #{time} s"
        @setValue true
        .then ->
          promise = Promise.delay time * 1000
          .cancellable
          .bind this
          .then -> @setValue false
          promise: promise
          cancel: -> promise.cancel
