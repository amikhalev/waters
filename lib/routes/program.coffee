Program = require("../models").Program
common = require "./common"

log = require("../log").child
  subsystem: "api"
  api: "program"
, true

makeMethod = common.makeMethod (Program)

module.exports =
  bind: (server, base) ->
    # CRUD routes
    common.crud Program, server, base
    # Other
    server.get "#{base}/:id/sections", @getSections
    server.put "#{base}/:id/sections", @setSections

  getSections: makeMethod "getSections", null, (sections) ->
    sections.map (section) ->
      id: section.id
      time: section.ProgramSection.time

  setSections: (req, res, next) ->
    ids = req.params.sections
    common.findById(Model)(req.params.id)
      .call "setSections", if param is true then req.params else req.params[param]
      .then -> res.send success arguments...
      .catch restify.HttpError, (err) -> res.send err
      .catch (err) -> res.send new RestError err
      .finally next()
