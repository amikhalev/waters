Promise = require "bluebird"
GPIO = require "../gpio"

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
        if @enabled
          GPIO.open @gpio
          .bind this
          .then -> GPIO.setDirection @gpio, GPIO.OUT
          .then -> GPIO.setValue @gpio, false
        else Promise.reject("Not enabled")
      deinit: ->
        if @enabled
          GPIO.setValue @gpio, false
          .bind this
          .then -> GPIO.close @gpio
        else Promise.reject("Not enabled")
      setValue: (value) ->
        if @enabled
          GPIO.setValue @gpio, value
        else Promise.reject("Not enabled")
      runFor: (time) ->
        log.trace
          action: "runFor"
          runTime: time
          id: @id
        , "runFor #{time}"
        if @enabled
          GPIO.setValue @gpio, true
          .delay time * 1000
          .bind this
          .then -> GPIO.setValue @gpio, false
        else Promise.reject("Not enabled")
