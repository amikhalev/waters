gulp = require "gulp"
rsync = require("rsyncwrapper").rsync
coffee = require "gulp-coffee"
sourcemaps = require "gulp-sourcemaps"
gutil = require "gulp-util"
del = require "del"
child = require "child_process"
format = require("util").format

options =
  files:
    coffee: "./{app.coffee,lib/**/*.coffee}"
    dist: "./dist"
  remote:
    host: "192.168.1.30"
    path: "/home/alex/waters"

gulp.task "build:scripts", ->
  gulp.src options.files.coffee,
      base: "."
    .pipe sourcemaps.init()
    .pipe coffee(
      bare: true
    ).on "error", (e) ->
      gutil.log e.toString()
    .pipe sourcemaps.write "./maps", sourceRoot: __dirname
    .pipe gulp.dest(options.files.dist)

gulp.task "build:copy", ->
  gulp.src [
    "package.json"
    "install.sh"
  ]
    .pipe gulp.dest(options.files.dist)
  return

gulp.task "build", [
  "build:scripts"
  "build:copy"
]
gulp.task "clean", (done) ->
  del options.files.dist, done

run = (params, done) ->
  proc = child.spawn("node", (params or []).concat ["./dist/app.js"])
  proc.on "error", (err) ->
    done err: err
    return

  proc.on "exit", done
  bunyan = child.spawn("node_modules/.bin/bunyan", ["--color"])
  proc.stdout.pipe bunyan.stdin
  bunyan.stdout.pipe process.stdout
  proc.stderr.pipe process.stderr

gulp.task "run:exec", ["build"], (done) ->
  run [], done

gulp.task "run", [
  "build"
  "run:exec"
]

gulp.task "debug:exec", ["build"], (done) ->
  run ["--debug-brk"], done

gulp.task "debug", [
  "build"
  "debug:exec"
]

gulp.task "deploy:upload", ["build"], (cb) ->
  rsync
    ssh: true
    src: "./dist/"
    dest: "alex@192.168.1.30:/home/alex/waters"
    recursive: true
    progress: true
  , (err, stdout, stderr) ->
      if err then cb err else cb()
      gutil.log stdout
      gutil.log stderr

gulp.task "deploy:install", ["deploy:upload"], (done) ->
  remoteCommand = format "cd '%s' && sh install.sh", options.remote.path
  proc = child.spawn("ssh", [
    options.remote.host
    remoteCommand
  ])
  proc.on "error", (err) ->
    done err: err
    return

  proc.on "exit", done
  proc.stderr.pipe process.stderr
  proc.stdout.pipe process.stdout
  return

gulp.task "deploy", [
  "deploy:upload"
  "deploy:install"
]

gulp.task "default", ["build"]
