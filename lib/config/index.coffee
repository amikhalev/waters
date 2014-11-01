_ = require "lodash"

env = process.env.NODE_ENV || "development"
module.exports = _.defaults require("./#{env}"),
  require "./default"
