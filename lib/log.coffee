bunyan = require "bunyan"
_ = require "lodash"
config = require "./config"

module.exports = log = bunyan.createLogger _.defaults
  name: "waters"
  level: process.env.LOG_LEVEL or "info"
  stream: process.stdout
  serializers: bunyan.stdSerializers
  ,
  config.bunyan
