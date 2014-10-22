require("source-map-support").install()

restify = require "restify"
bunyan = require "bunyan"
Sequelize = require "sequelize"

log = require "./lib/log"

sequelizeLog = log.child subsystem: "sequelize", true

sequelize = new Sequelize "database", "username", "password",
  dialect: "sqlite"
  storage: "database.sqlite"
  logging: -> sequelizeLog.trace arguments...

models = require("./lib/models/")(sequelize)

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
  require("./lib/mock")(sequelize, models, sequelizeLog)
.tap -> log.info "Created mock models"
.catch (err) ->
  log.error err, "Failed to create mock models"
  process.exit -1
.then ->
  httpLog = log.child subsystem: "http", true

  routes = require("./lib/routes/")

  server = restify.createServer
    log: httpLog
    name: "waters"

  server.use restify.acceptParser(server.acceptable)
  server.use restify.authorizationParser()
  server.use restify.dateParser()
  server.use restify.queryParser()
  server.use restify.bodyParser()
  server.use restify.requestLogger()
  #server.on('after', restify.auditLogger({ log: log }));

  #log.info "%j", routes
  routes.gpio.bind server, "/api/gpio"

  port = process.argv[2] or process.env["PORT"] or 8080
  server.listen port, ->
    log.info "%s listening at %s", server.name, server.url
