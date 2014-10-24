restify = require "restify"
Sequelize = require "sequelize"
GPIO = require "./gpio"

module.exports = errors =
  APIError: class APIError extends Error
    constructor: (@name, @message, @status) ->

  SequelizeError: class SequelizeError extends APIError
    constructor: (err) ->
      status = if err instanceof Sequelize.ValidationError then 400 else 500
      message = if err instanceof Sequelize.ValidationError then err.errors else err.message
      super "SequelizeError", message, status

  RestError: class RestError extends restify.RestError
    constructor: (err) ->
      if err instanceof restify.RestError
        return err
      super
        restCode: err.name
        statusCode: err.status or 500
        message: err.message
        constructorOpt: RestError
      @name = err.name
