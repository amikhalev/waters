require("source-map-support").install()

restify = require "restify"
bunyan = require "bunyan"
config = require "./lib/config"
log = require "./lib/log"
models = require "./lib/models/"
GPIO = require "./lib/gpio"
sequelize = models.sequelize
mock = require "./lib/mock"

GPIO.stub()

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
  mock()
.tap -> log.info "Created mock models"
.catch (err) ->
  log.error err, "Failed to create mock models"
  process.exit -1
.then ->
  httpLog = log.child subsystem: "http", true

  routes = require("./lib/routes/")

  server = restify.createServer
    log: httpLog
    name: config.name

  server.use restify.acceptParser(server.acceptable)
  server.use restify.authorizationParser()
  server.use restify.dateParser()
  server.use restify.queryParser()
  server.use restify.bodyParser()
  server.use restify.requestLogger()
  #server.on('after', restify.auditLogger({ log: log }));

  #log.info "%j", routes
  routes.gpio.bind server, "/api/gpios"
  routes.section.bind server, "/api/sections"

  port = config.server.port
  server.listen port, ->
    log.info "%s listening at %s", server.name, server.url
