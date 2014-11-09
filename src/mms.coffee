require 'coffee-script/register'
coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
colors = require 'colors'
async = require 'async'

config = require './config'
pkg = require '../package.json'

# Register global functions
global.mongo = require './mongo'

try
  rcPath = path.join process.env.HOME, '.mmsrc.json'
  config = util._extend config, require rcPath
catch e

{ext, dir} = config

template = """
exports.up = (next) ->

exports.down = (next) ->
"""

###*
 * Compile the migrate template to Javascript file when use the Javascript pattern
 * @type {[type]}
###
template = coffee.compile template, bare: true if config.ext is '.js'

_loadTasks = ->
  files = fs.readdirSync config.dir
  files = files.filter (file) -> if file.match /^[0-9]{13}\-.*\.(js|coffee)$/ then true else false
  files.sort (x, y) -> Number(x.split('-')[0]) - Number(y.split('-')[0])
  .map (file) -> name: file.split('.')[0], path: file

_runTask = (task, next = ->) ->
  task = require task.path
  {up, down} = task
  if up.length is 0
    up()
    next()
  else
    up next

mms = module.exports

mms.version = pkg.version

mms.create = (name) ->
  timestamp = Date.now()
  file = path.join config.dir, "#{timestamp}-#{name}#{ext}"
  mkdirp.sync dir
  fs.writeFileSync file, template
  console.log '  create'.cyan, file.grey

mms.migrate = (name) ->
  tasks = _loadTasks()

mms.rollback = (name) ->

mms.status = ->

# class MMS

#   constructor: ->
#     @_loadrc()

#   _loadrc: ->
#     try
#       config = util._extend config,
#         require path.resolve('./.mmsrc.json')
#     catch e

#   _checkVersion: (name, migrations) ->
#     return true unless name?
#     versionIdx = {}
#     nameIdx = {}
#     for title, migration of migrations
#       versionIdx[title[0...13]] = 1
#       nameIdx[title[14..]] = 1
#     unless versionIdx[name] or nameIdx[name] or name?.match /[0-9]{1,5}/
#       console.error '  fail'.red, "migration [#{name}] not found!".grey
#       process.exit(1)

#   _migrate: (file, callback = ->) ->
#     isCoffee = true if path.extname(file) is '.coffee'
#     async.waterfall [
#       (next) ->
#         filePath = path.join config.dir, file
#         if isCoffee
#           exec "coffee -c #{filePath}", (err) ->
#             filePath = filePath.replace '.coffee', '.js'
#             next err, filePath
#         else
#           next null, filePath
#       (filePath, next) ->
#         child = exec "mongo #{config.db} --quiet #{filePath}", (err) -> next err, filePath
#         child.stdout.on 'data', (data) -> process.stdout.write data
#         child.stderr.on 'data', (data) -> process.stderr.write data
#       (filePath, next) ->
#         fs.unlinkSync filePath if isCoffee
#         next()
#     ], (err) ->
#       if err?
#         console.error '  fail'.red, file.grey
#         process.exit(2)
#       else
#         console.log '  succ'.green, file.grey
#         callback()

#   # Create new migration files
#   create: (name, options = {}, callback = ->) ->
#     timestamp = Date.now()
#     ext = config.ext or '.js'
#     upFile = path.join config.dir, "#{timestamp}_up_#{name}#{ext}"
#     downFile = path.join config.dir, "#{timestamp}_down_#{name}#{ext}"

#     mkdirp.sync config.dir
#     fs.writeFileSync upFile, ''
#     console.log '  create'.cyan, upFile.grey
#     fs.writeFileSync downFile, ''
#     console.log '  create'.cyan, downFile.grey
#     callback()

#   # Start migration
#   migrate: (name, options = {}, callback = ->) ->
#     migrations = @_loadMigrations()
#     @_checkVersion(name, migrations)
#     try
#       schema = require path.resolve(config.schema)
#     catch e
#       schema = {}
#     newSchema = {}

#     step = 0
#     async.eachSeries Object.keys(migrations), (title, next) =>
#       if schema[title]? and schema[title].status is 'up'
#         newSchema[title] = status: 'up'
#         next()
#       else
#         migration = migrations[title]
#         console.log '  migrate'.cyan, title.grey
#         @_migrate migration.up, ->
#           step += 1
#           newSchema[title] = status: 'up'
#           fs.writeFileSync config.schema, JSON.stringify(newSchema, null, 2)
#           return next() unless name?
#           if name.match /[0-9]{1,5}/ and step is Number(name)
#             return next('finish')
#           if title.indexOf(name) > -1
#             return next('finish')
#           next()
#     , (err) ->
#       console.log '  complete'.cyan
#       callback()

#   # Rollback to the former version
#   rollback: (name, options = {}, callback = ->) ->
#     migrations = @_loadMigrations()
#     @_checkVersion(name, migrations)

#     try
#       schema = require path.resolve(config.schema)
#     catch e
#       schema = {}

#     step = 0
#     titles = Object.keys(schema)
#     titles.sort (x, y) -> 1

#     async.eachSeries titles, (title, next) =>
#       step += 1
#       migration = migrations[title]
#       unless migration?
#         delete schema[title]
#         return next()
#       console.log '  rollback'.cyan, title.grey
#       @_migrate migration.down, ->
#         delete schema[title]
#         fs.writeFileSync config.schema, JSON.stringify(schema, null, 2)
#         return next() unless name?
#         if name.match /[0-9]{1,5}/ and step is Number(name)
#           return next('finish')
#         if title.indexOf(name) > -1
#           return next('finish')
#         next()
#     , (err) ->
#       console.log '  complete'.cyan
#       callback()

#   status: (callback = ->) ->
#     migrations = @_loadMigrations()
#     try
#       schema = require path.resolve(config.schema)
#     catch e
#       schema = {}
#     status = {}
#     console.log '  status'.cyan
#     for title, migration of migrations
#       if schema[title]?.status is 'up'
#         status[title] = 'up'
#         console.log "  up".green, title.grey
#       else
#         status[title] = 'down'
#         console.log "  down".red, title.grey
#     callback(null, status)
