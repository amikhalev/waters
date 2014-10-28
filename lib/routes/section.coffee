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

checkExists = (sec) ->
  if not sec or sec.length is 0 then throw new restify.NotFoundError "Section not found"
  sec

findById = (id) ->
  Section.find where: id: id
  .then (sec) -> checkExists sec
  , (err) -> throw new SequelizeError err

module.exports =
  bind: (server, base) ->
    server.post "#{base}", @add
    server.get "#{base}", @get
    server.get "#{base}/:id", @get
    server.patch "#{base}/:id", @update
    server.del "#{base}/:id", @destroy
    server.get "#{base}/:id/init", @isInitialized
    server.post "#{base}/:id/init", @init
    server.post "#{base}/:id/deinit", @deinit
#    server.get "#{base}/:id/gpio", @getGPIO
#    server.put "#{base}/:id/gpio", @setGPIO
    server.put "#{base}/:id/value", @setValue
    server.post "#{base}/:id/runFor", @runFor

  get: (req, res, next) ->
    Section.findAll
      where: req.params
    .then checkExists
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

  isInitialized: (req, res, next) ->
    findById req.params.id
    .then (sec) ->
      sec.isInitialized()
    .then (initialized) ->
      res.send initialized: initialized
    , (err) -> res.send new RestError err
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

  runFor: (req, res, next) ->
    findById req.params.id
    .then (sec) ->
      sec.runFor req.params.time
    .then ->
      res.send status: "success"
    , (err) -> res.send new RestError err
    .finally -> next()
