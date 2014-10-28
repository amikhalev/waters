restify = require "restify"
models = require "../models"
Program = models.Program
errors = require("../errors")
SequelizeError = errors.SequelizeError
RestError = errors.RestError

log = require("../log").child
  subsystem: "api"
  api: "program"
, true

module.exports =
  bind: (server, base) ->
