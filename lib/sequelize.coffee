models = require "./models/"
sequelize = models.sequelize
mock = require "./mock"

log = require("./log").child
  subsystem: "sequelize"

module.exports = ->
  log.info "Syncing sequelize models..."
  sequelize.sync()
  .tap ->
    log.info "Successfully synced sequelize models"
  .catch (err) ->
    log.error err, "Failed to sync sequelize models"
    process.exit -1
  .then ->
    # mock data
    log.info "Creating mock models"
  #  mock()
  .tap -> log.info "Created mock models"
  .catch (err) ->
    log.error err, "Failed to create mock models"
    process.exit -1
