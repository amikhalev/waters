Promise = require "bluebird"
models = require "./models"
sequelize = models.sequelize
sequential = require("./util").sequential;

module.exports = ->
  log = models.log
  sequential [
    -> models.Section.findOrCreate
        where:
          name: "Front 1"
          description: ""
          gpio: 21
          enabled: true
    -> models.Section.findOrCreate
      where:
        name: "Front 2"
        description: ""
        gpio: 22
        enabled: true
    -> models.Program.findOrCreate
        where:
          name: "Morning"
          enabled: true
          when: "at 10:25 AM"
  ]
  .spread (sec1, sec2, prog) ->
    sec1 = sec1[0]
    sec2 = sec2[0]
    prog = prog[0]
    sec1.ProgramSections = time: 5
    sec2.ProgramSections = time: 5
    prog.setSections [sec1, sec2]
    .then -> sec1.init()
    .then -> sec2.init()
    .then ->
#      prog.run()
#      .props (promise, cancel) ->
#        Promise.delay 2500
#          .then -> cancel()
  .then ->
    log.info "Initialized"
  .catch sequelize.ValidationError, (e) -> log.error e.errors, "SequelizeValidationError"
