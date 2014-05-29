fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
colors = require 'colors'
config = require './config'

class MMS

  constructor: () ->
    @_loadrc()

  _loadrc: ->
    try
      config = util._extend config,
        require path.resolve('./.mmsrc.json')
    catch e

  _loadMigrations: ->

  # Create new migration files
  create: (name, options = {}, callback = ->) ->
    timestamp = Date.now()
    ext = config.ext or '.js'
    upFile = path.join config.dir, "#{timestamp}_up_#{name}#{ext}"
    downFile = path.join config.dir, "#{timestamp}_down_#{name}#{ext}"

    mkdirp.sync config.dir
    fs.writeFileSync upFile, ''
    console.log '  create up file:'.cyan, upFile.grey
    fs.writeFileSync downFile, ''
    console.log '  create down file:'.cyan, downFile.grey
    callback()

  # Start migration
  migrate: (name, options = {}, callback = ->) ->

  # Rollback to the former version
  rollback: (name, options = {}, callback = ->) ->

  status: (callback = ->) ->

module.exports = new MMS
