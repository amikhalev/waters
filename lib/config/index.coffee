_ = require "lodash"

env = process.env.ENV || "dev"
module.exports = _.defaults require("./#{env}"),
  require "./default"
