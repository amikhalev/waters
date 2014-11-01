express = require "express"
errors = require "./../errors"
APIError = errors.APIError
SequelizeError = errors.SequelizeError

module.exports = common =
  checkExists: (Model) ->
    (model) ->
      if not model or model.length is 0 then throw new APIError "NotFoundError", "#{Model.name} not found", 404
      model
  findById: (Model) ->
    (id) ->
      Model.find where: id: id
      .catch (err) -> throw new SequelizeError err
      .then (sec) -> common.checkExists(Model)(sec)
  makeMethod: (Model) ->
    (name, param, ret) ->
      success = if typeof ret is "function" then ret
      else if ret is true then (r) -> r
      else if ret then (r) ->
        obj = {}
        obj[ret] = r
        obj
      else -> status: "success"
      (req, res, next) ->
        common.findById(Model)(req.params.id)
        .call name, if param is true then req.params else req.params[param]
        .then -> res.send success arguments...
        .catch next
  crud: (Model, server, base) ->
    @findAll = (req, res, next) ->
      Model.findAll where: req.query
      .then common.checkExists Model
      .catch next
      .then (models) -> res.send models
      .catch (err) -> next new SequelizeError err

    @find = (req, res, next) ->
      Model.find
        where: req.query
      .then common.checkExists Model
      .catch next
      .then (model) -> res.send model
      .catch (err) -> next new SequelizeError err

    @exists = (req, res, next) ->
      Model.count
        where: req.query
      .then (count) -> res.send exists: count > 0
      .catch (err) -> next new SequelizeError err

    @count = (req, res, next) ->
      Model.count
        where: req.query
      .then (count) -> res.send count: count
      .catch (err) -> next new SequelizeError err

    @add = (req, res, next) ->
      Model.create req.query
      .then (model) -> res.send model
      .catch (err) -> next new SequelizeError err

    @update = (req, res, next) ->
      Model.update req.query,
        where: id: req.params.id
      .then (num) -> res.send updated: num
      .catch (err) -> next new SequelizeError err

    @destroy = (req, res, next) ->
      Model.destroy req.query
      .then (num) -> res.send destroyed: num
      .catch (err) -> next new SequelizeError err

    server.get "#{base}", @findAll
    server.post "#{base}", @add
    server.get "#{base}/findOne", @find
    server.get "#{base}/count", @count
    server.get "#{base}/:id/exists", @exists
    server.get "#{base}/:id", @find
    server.put "#{base}/:id", @update
    server.delete "#{base}/:id", @destroy
