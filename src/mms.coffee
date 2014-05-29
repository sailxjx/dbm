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
    files = files.filter (file) -> if file.match /^[0-9]{13}_(up|down)_.*\.(js|coffee)$/ then true else false
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
      console.error '  fail'.red, "migration [#{name}] not found!".grey
      process.exit(1)

  _migrate: (file, callback = ->) ->
    console.log '  migrate'.cyan, file.grey
    isCoffee = true if path.extname(file) is '.coffee'
    async.waterfall [
      (next) ->
        filePath = path.join config.dir, file
        if isCoffee
          exec "coffee -c #{filePath}", (err) ->
            filePath = filePath.replace '.coffee', '.js'
            next err, filePath
        else
          next null, filePath
      (filePath, next) ->
        child = exec "mongo #{config.db} --quiet #{filePath}", (err) -> next err, filePath
        child.stdout.on 'data', (data) -> process.stdout.write data
        child.stderr.on 'data', (data) -> process.stderr.write data
      (filePath, next) ->
        fs.unlinkSync filePath if isCoffee
        next()
    ], (err) ->
      if err?
        console.error '  fail'.red, file.grey
        process.exit(2)
      else
        console.log '  succ'.green, file.grey
        callback()

  # Create new migration files
  create: (name, options = {}, callback = ->) ->
    timestamp = Date.now()
    ext = config.ext or '.js'
    upFile = path.join config.dir, "#{timestamp}_up_#{name}#{ext}"
    downFile = path.join config.dir, "#{timestamp}_down_#{name}#{ext}"

    mkdirp.sync config.dir
    fs.writeFileSync upFile, ''
    console.log '  create'.cyan, upFile.grey
    fs.writeFileSync downFile, ''
    console.log '  create'.cyan, downFile.grey
    callback()

  # Start migration
  migrate: (name, options = {}, callback = ->) ->
    migrations = @_loadMigrations()
    @_checkVersion(name, migrations)
    try
      schema = require path.resolve(config.schema)
    catch e
      schema = {}
    newSchema = {}

    step = 0
    async.eachSeries Object.keys(migrations), (title, next) =>
      if schema[title]? and schema[title].status is 'up'
        console.log '============'
        newSchema[title] = status: 'up'
        next()
      else
        migration = migrations[title]
        @_migrate migration.up, ->
          step += 1
          newSchema[title] = status: 'up'
          fs.writeFileSync config.schema, JSON.stringify(newSchema, null, 2)
          if name.match /[0-9]{1,5}/ and step is Number(name)
            return next('finish')
          if title.indexOf(name) > -1
            return next('finish')
          next()
    , (err) ->
      console.log '  complete'.cyan
      callback()

  # Rollback to the former version
  rollback: (name, options = {}, callback = ->) ->
    migrations = @_loadMigrations()
    @_checkVersion(name, migrations)
    callback()

  status: (callback = ->) ->

module.exports = new MMS
