readline = require "readline"
restify = require "restify"

out = console.log
error = console.error

host = process.argv[2] || 'localhost'
port = process.argv[3] || 8080
url = "http://#{host}:#{port}"

client = restify.createJsonClient
  url: url
  version: "*"

printHelp = (cmds, pre) ->
  pre = pre or ""
  for name, cmd of cmds
    message = pre + name
    message += " <#{arg}>" for arg in cmd.args if cmd.args
    message += new Array(20 - message.length).join " "
    message += cmd.description or ""
    out message
    if cmd.subcommands
      printHelp cmd.subcommands, "#{pre}#{name} "

commands = [
  name: "help"
  description: "Prints out this help message"
  fn: ->
    out "Commands: "
    for cmd in commands
      message = cmd.name
      message += new Array(20 - message.length).join " "
      message += cmd.description or ""
      out message
    rl.prompt()
,
  name: "gpio list"
  description: "List gpios"
  fn: ->
    out "GPIOs:"
    client.get "/api/gpios", (err, req, res, obj) ->
      if err then error err
      else out obj
      rl.prompt()
,
  name: "gpio opens"
  description: "List open gpios"
  fn: ->
    out "Open GPIOs:"
    client.get "/api/gpios/open", (err, req, res, obj) ->
      if err then error err
      else out obj
      rl.prompt()
,
  name: "gpio <gpio> open"
  description: "Open a gpio"
  fn: (gpio) ->
    error gpio
    client.post "/api/gpios/#{gpio}", (err, req, res, obj) ->
      if err then error err
      else out obj
      rl.prompt()
,
  name: "gpio <gpio> close"
  description: "Close a gpio"
  fn: (gpio) ->
    client.del "/api/gpios/#{gpio}", (err, req, res, obj) ->
      if err then error err
      else out obj
      rl.prompt()
]

for cmd in commands
  str = cmd.name
  str = str.replace /<[^>]+>/, "([^ ]+)"
  cmd.regexp = new RegExp str, "i"

rl = readline.createInterface
  input: process.stdin
  output: process.stdout
  completer: (line) ->
    cmds = commands.map (cmd) -> cmd.name
    hits = cmds.filter (cmd) ->
      cmd.indexOf(line) isnt -1
    hits = if hits.length then hits else cmds
    [hits, line]

rl.setPrompt "[waters]> ", 0

rl.on "line", (line) ->
  for cmd in commands
    res = cmd.regexp.exec line
    if res
      return cmd.fn.apply null, res[1..]
  error "#{line} is not a command"
  rl.prompt()

out "waters client for #{url}"
rl.prompt()
