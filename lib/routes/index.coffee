fs = require "fs"
module.exports = routes = fs.readdirSync __dirname
  .filter (file) -> not /^\.|index\.(js|coffee)/.test file
  .map (file) -> file.replace /\.(js|coffee)$/, ""
  .reduce (mods, mod) ->
    mods[mod] = require "./" + mod
    mods
  , {}
