fs = require "fs"
module.exports = routes = fs.readdirSync "."
  .map require
