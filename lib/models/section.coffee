Promise = require "bluebird"
_ = require "lodash"
GPIO = require "../gpio"
errors = require "../errors"
APIError = errors.APIError

log = require("../log").child
  subsystem: "models"
  model: "Section"
, true

initialized = []

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
      isInitialized: ->
        @gpio in initialized
      init: ->
        log.trace
          action: "init"
          id: @id
        , "init section #{@name}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if @isInitialized() then Promise.reject new APIError "AlreadyInitializedError", "Section already initialized"
        else
          GPIO.open @gpio
          .bind this
          .then -> GPIO.setDirection @gpio, GPIO.OUT
          .then -> GPIO.setValue @gpio, false
          .tap -> initialized.push @gpio
      deinit: ->
        log.trace
          action: "deinit"
          id: @id
        , "deinit section #{@name}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if not @isInitialized() then Promise.reject new APIError "NotInitializedError", "Section not initialized"
        else
          GPIO.setValue @gpio, false
          .bind this
          .then -> GPIO.close @gpio
          .tap -> initialized = _.remove initialized, @gpio
      setGPIO: (gpio) ->
        log.trace
          action: "setGPIO"
          id: @id
          gpio: gpio
        , "setGPIO section #{@name}, #{gpio}"
        if @enabled and @isInitialized()
          @deinit()
          .bind this
          .then -> @gpio = gpio
          .then -> @init()
          .catch (e) -> log.error e, "Error changing gpio on section #{@id}"
        else @gpio = gpio
      setValue: (value) ->
        log.trace
          action: "setValue"
          id: @id
          value: value
        , "setValue section #{@name}, #{value}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if not @isInitialized() then Promise.reject new APIError "NotInitializedError", "Section not initialized"
        else
          GPIO.setValue @gpio, value
      getValue: ->
        log.trace
          action: "getValue"
          id: @id
        , "getValue section #{@name}"
        if not @enabled then Promise.reject new APIError "NotEnabledError", "Section not enabled"
        else if not @isInitialized() then Promise.reject new APIError "NotInitializedError", "Section not initialized"
        else
          GPIO.getValue @gpio
      runFor: (time) ->
        log.trace
          action: "runFor"
          runTime: time
          id: @id
        , "runFor #{time} s"
        @setValue true
        .bind this
        .then ->
          promise = Promise.delay time * 1000
          .cancellable()
          .bind this
          .then -> @setValue false
          promise: promise
          cancel: -> promise.cancel
