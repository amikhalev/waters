fs = require "fs"
path = require "path"
Sequelize = require "sequelize"
_ = require "lodash"
config = require "../config"
log = require "../log"

sqlLog = log.child subsystem: "sequelize", true

csql = config.sequelize
sequelize = new Sequelize csql.database, csql.username, csql.password,
  _.defaults csql, logging: -> sqlLog.trace arguments...

models = {}

fs.readdirSync(__dirname)
  .filter (file) ->
    not /^\.|index\.(js|coffee)/.test file
  .forEach (file) ->
    model = sequelize.import path.join __dirname, file
    models[model.name] = model

for name, model of models
  model.associate models if model.associate

models.Sequelize = Sequelize
models.sequelize = sequelize
models.log = sqlLog

module.exports = models
