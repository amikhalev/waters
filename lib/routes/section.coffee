restify = require "restify"
models = require "../models"
Section = models.Section
errors = require("../errors")
SequelizeError = errors.SequelizeError
RestError = errors.RestError

log = require("../log").child
  subsystem: "api"
  api: "section"
, true

findById = (id) ->
  Section.find where: id: id
  .then (sec) ->
    if not sec then throw new restify.NotFoundError "Section not found"
    sec
  , (err) -> throw new SequelizeError err

module.exports =
  bind: (server, base) ->
    server.post "#{base}", @add
    server.get "#{base}", @get
    server.get "#{base}/:id", @get
    server.put "#{base}/:id", @update
    server.del "#{base}/:id", @destroy
    server.post "#{base}/:id/init", @init
    server.post "#{base}/:id/deinit", @deinit
    server.put "#{base}/:id/value", @setValue

  get: (req, res, next) ->
    Section.findAll
      where: req.params
    .then (sections) ->
      res.send sections
    , (err) ->
      res.send new RestError new SequelizeError err
    .finally -> next()

  add: (req, res, next) ->
    Section.create req.params
    .then (sec) ->
      res.send sec
    , (err) -> res.send new RestError new SequelizeError err
    .finally -> next()

  update: (req, res, next) ->
    Section.update req.params, id: req.params.id
    .then (num) ->
      res.send updated: num
    , (err) -> res.send new RestError new SequelizeError err
    .finally -> next()

  destroy: (req, res, next) ->
    Section.destroy req.params
    .then (num) ->
      res.send deleted: num
    , (err) -> res.send new RestError new SequelizeError err
    .finally -> next()

  init: (req, res, next) ->
    findById req.params.id
    .then (sec) ->
      sec.init()
    .then ->
      res.send status: "success"
    , (err) -> res.send new RestError err
    .finally -> next()

  deinit: (req, res, next) ->
    findById req.params.id
    .then (sec) ->
      sec.deinit()
    .then ->
      res.send status: "success"
    , (err) -> res.send new RestError err
    .finally -> next()

  setValue: (req, res, next) ->
    findById id: req.params.id
    .then (sec) ->
      sec.setValue req.params.value
    .then ->
      res.send value: req.params.value
    , (err) -> res.send new RestError err
    .finally -> next()
