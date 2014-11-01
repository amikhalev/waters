Section = require("../models").Section
common = require "./common"

log = require("../log").child
  subsystem: "api"
  api: "section"
, true

makeMethod = common.makeMethod (Section)

module.exports =
  bind: (server, base) ->
    # CRUD routes
    common.crud Section, server, base
    # Method routes
    server.get "#{base}/:id/init", @isInitialized
    server.post "#{base}/:id/init", @init
    server.post "#{base}/:id/deinit", @deinit
    server.get "#{base}/:id/gpio", @getGPIO
    server.put "#{base}/:id/gpio", @setGPIO
    server.get "#{base}/:id/value", @getValue
    server.put "#{base}/:id/value", @setValue
    server.post "#{base}/:id/runFor", @runFor

  isInitialized: makeMethod "isInitialized", null, "initialized"
  init: makeMethod "init"
  deinit: makeMethod "deinit"
  getValue: makeMethod "getValue", null, "value"
  setValue: makeMethod "setValue", "value", null
  getGPIO: makeMethod "getGPIO", null, "gpio"
  setGPIO: makeMethod "setGPIO", "gpio", null
  runFor: makeMethod "runFor", "time", null
