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
    coffee: [
      "./app.coffee"
      "./lib/**/*.coffee"
    ]
    maps: "./maps"
    dist: "./dist"
    clean: "./dist"
    run: "./dist/app.js"
    copy:
      src: [
        "package.json"
        "install.sh"
      ]
      dest: "./dist"
  remote:
    host: "192.168.1.30"
    path: "/home/alex/waters"

gulp.task "build:scripts", ->
  gulp.src options.files.coffee,
      base: "."
    .pipe sourcemaps.init()
    .pipe coffee(
      bare: true
    ).on('error', gutil.log)
    .pipe sourcemaps.write()
    .pipe gulp.dest(options.files.dist)

gulp.task "build:copy", ->
  gulp.src options.files.copy.src
    .pipe gulp.dest(options.files.copy.dest)
  return

gulp.task "build", [
  "build:scripts"
  "build:copy"
]
gulp.task "clean", (done) ->
  del options.files.clean, done

gulp.task "run:exec", ["build"], (done) ->
  proc = child.spawn("node", [options.files.run])
  proc.on "error", (err) ->
    done err: err
    return

  proc.on "exit", done
  bunyan = child.spawn("node_modules/.bin/bunyan", ["--color"])
  proc.stdout.pipe bunyan.stdin
  bunyan.stdout.pipe process.stdout
  proc.stderr.pipe process.stderr
  return

gulp.task "run", [
  "build"
  "run:exec"
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
