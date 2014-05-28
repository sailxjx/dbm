fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
config = require './config'
logger = require './logger'

class MMS

  constructor: () ->
    @_loadrc()

  _loadrc: ->
    try
      config = util._extend config,
        require '.mmsrc.json'
    catch e

  _loadMigrations: ->

  # Create new migration files
  create: (name, callback = ->) ->
    timestamp = Date.now()
    ext = '.js'
    upFile = path.join config.dir, "#{timestamp}_up_#{name}#{ext}"
    downFile = path.join config.dir, "#{timestamp}_down_#{name}#{ext}"

    mkdirp.sync config.dir
    fs.writeFileSync upFile, ''
    logger.info 'create up file:', upFile
    fs.writeFileSync downFile, ''
    logger.info 'create down file:', downFile

  # Start migration
  migrate: (name, callback = ->) ->

  # Rollback to the former version
  rollback: (name, callback = ->) ->

module.exports = new MMS
