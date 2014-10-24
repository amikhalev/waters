Promise = require "bluebird"

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
