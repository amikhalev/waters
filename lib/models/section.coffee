Sequelize = require "sequelize"
GPIO = require "../gpio"

module.exports = (sequelize) ->
  sequelize.define 'Section',
    name:
      type: Sequelize.STRING
      allowNull: false
    description:
      type: Sequelize.STRING
    gpio:
      type: Sequelize.INTEGER
      allowNull: false
      validate:
        isIn:
          args: [GPIO.gpios]
          msg: "Must be a gpio pin"
    enabled:
      type: Sequelize.BOOLEAN
    ,{},
    init: ->
      GPIO.open this.gpio if this.enabled
    deinit: ->
      GPIO.close this.gpio if this.enabled
