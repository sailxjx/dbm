fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
colors = require 'colors'
async = require 'async'
{exec} = require 'child_process'
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
    migrations = {}
    files = fs.readdirSync config.dir
    files = files.filter (file) ->
      return false unless file.match /^[0-9]{13}_(up|down)_.*\.(js|coffee)$/
    files.sort (x, y) -> Number(x.split('_')[0]) - Number(y.split('_')[0])
    files.forEach (file) ->
      title = file.replace /^[0-9]{13}_(up|down)/, (code) -> code.split('_')[0]
      upFile = title.replace /^[0-9]{13}/, (code) -> code + '_up'
      downFile = title.replace /^[0-9]{13}/, (code) -> code + '_down'
      title = title.split('.')[0]  # Remove extension name of title
      if upFile in files and downFile in files
        migrations[title] =
          up: upFile
          down: downFile
      else
        delete migrations[title]
    return migrations

  _checkVersion: (name, migrations) ->
    versionIdx = {}
    nameIdx = {}
    for title, migration of migrations
      versionIdx[title[0...13]] = 1
      nameIdx[title[14..]] = 1
    unless versionIdx[name] or nameIdx[name] or name.match /[0-9]{1,5}/
      console.error '  err!:'.red, "migration [#{name}] not found!".grey
      process.exit(1)

  _migrate: (file, callback = ->) ->
    console.log '  migrate:'.cyan, file.grey
    filePath = path.join config.dir, file
    async.waterfall [
      (next) ->
        if path.extname(filePath) is 'coffee'
          exec "coffee -c #{filePath}", (err) -> next err
        else
          next()
      (next) ->
        if path.extname(filePath) is 'coffee'
          _filePath = filePath.replace '.coffee', '.js'
        else
          _filePath = filePath
        child = exec "mongo #{config.db} --quiet #{_filePath}", (err) -> next(err)
        child.stdout.on 'data', (data) -> process.stdout.write data
        child.stderr.on 'data', (data) -> process.stderr.write data
      (next) ->
        if path.extname(filePath) is 'coffee'
          fs.unlinkSync filePath.replace '.coffee', '.js'
        next()
    ], (err) ->
      if err?
        console.error '  fail:'.red, "#{file}"
        process.exit(2)
      else
        console.log '  succ:'.green, "#{file}"
        callback()

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
    migrations = @_loadMigrations()
    @_checkVersion(name, migrations)
    schema = require config.schema
    newSchema = {}

    async.eachSeries Object.keys(migrations), (title, next) ->
      if schema[title]? and schema[title].status is 'up'
        newSchema[title] = status: 'up'
        next()
      else
        migration = migrations[title]
        @_migrate migration.up, ->
          newSchema[title] = status: 'up'
          fs.writeFileSync config.schema, JSON.stringify(newSchema, null, 2)
          next()
    , callback

  # Rollback to the former version
  rollback: (name, options = {}, callback = ->) ->
    migrations = @_loadMigrations()
    @_checkVersion(name, migrations)
    callback()

  status: (callback = ->) ->

module.exports = new MMS
