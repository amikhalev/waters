express = require "express"
Sequelize = require "sequelize"
GPIO = require "./gpio"

module.exports = errors =
  APIError: class APIError extends Error
    constructor: (@name, @message, @status) ->
      Error.captureStackTrace this, @constructor

  SequelizeError: class SequelizeError extends APIError
    constructor: (err) ->
      status = if err instanceof Sequelize.ValidationError then 400 else 500
      message = if err instanceof Sequelize.ValidationError then err.errors else err.message
      super "SequelizeError", message, status
