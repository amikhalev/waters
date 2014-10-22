bunyan = require "bunyan"

module.exports = log = bunyan.createLogger(
  name: "waters"
  level: process.env.LOG_LEVEL or "info"
  stream: process.stdout
  serializers: bunyan.stdSerializers
)
