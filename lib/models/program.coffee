Promise = require "bluebird"
later = require "later"

log = require("../log").child
  subsystem: "models"
  model: "Program"
, true

module.exports = (sequelize, DataTypes) ->
  ProgramSections = sequelize.define "ProgramSections",
    time:
      type: DataTypes.FLOAT
      allowNull: false
  Program = sequelize.define "Program",
    name: type: DataTypes.STRING
    enabled: type: DataTypes.BOOLEAN
    when:
      type: DataTypes.STRING
      allowNull: false
  ,
    classMethods:
      associate: (models) ->
        Program.hasMany models.Section, through: ProgramSections
        models.Section.hasMany Program, through: ProgramSections
    instanceMethods:
      run: ->
        log.trace
          action: "run"
          id: @id
          programName: @name
        , "run program #{@name}"
        if @enabled
          @getSections()
          .each (section) ->
            if section.enabled
              section.runFor section.ProgramSection.time
        else Promise.reject "Not enabled"
      schedule: ->
        later.date.localTime()
        sched = later.parse.text @when
        if sched.error isnt -1
          return log.error "invalid schedule \"#{@when}\": error at #{sched.error}"
        log.trace
          action: "schedule"
          id: @id
        , "Scheduling program #{@name}. Next start at #{later.schedule(sched).next(1)}"
        later.setInterval =>
          @run()
        , sched
