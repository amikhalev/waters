module.exports = (sequelize, models, log) ->
  models.Section.findOrCreate
    where:
      name: "Front 1"
      description: ""
      gpio: 21
      enabled: true
  .then (sec) ->
    log.error sec
