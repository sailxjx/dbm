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
  next()

exports.down = (next) ->
  next()
"""

###*
 * Compile the migrate template to Javascript file when use the Javascript pattern
 * @type {[type]}
###
template = coffee.compile template, bare: true if config.ext is '.js'

schema = null

_loadSchema = ->
  try
    schema = require config.schema
  catch e
    schema = {}
  schema

_saveSchema = (task, status) ->
  {name} = task
  if status is 'down' and schema[name]
    delete schema[name]
    fs.writeFileSync config.schema, JSON.stringify(schema)

  if status is 'up' and not schema[name]
    schema[name] = status: 'up'
    fs.writeFileSync config.schema, JSON.stringify(schema)

_loadTasks = ->
  files = fs.readdirSync config.dir
  files = files.filter (file) -> if file.match /^[0-9]{13}\-.*\.(js|coffee)$/ then true else false
  files.sort (x, y) -> Number(x.split('-')[0]) - Number(y.split('-')[0])
  .map (file) -> name: file.split('.')[0], path: path.resolve(path.join(config.dir, file))

_migrate = (fnName, task, callback) ->
  {name} = task

  try
    migration = require task.path
    fn = migration[fnName]
  catch e

  return callback(new Error('INVALID MIGRATION: ' + task.name)) unless typeof fn is 'function'

  schema = _loadSchema() unless schema

  if fnName is 'up' and schema[name]
    return callback()

  if fnName is 'down' and not schema[name]
    return callback()

  if fn.length is 0
    try
      fn()
    catch err
    callback err
  else
    fn callback

_up = (task, callback) ->
  {name} = task
  _migrate 'up', task, (err) ->
    return callback(err) if err
    console.log '  up'.green, name.grey
    callback null

_down = (task, callback) ->
  {name} = task
  _migrate 'down', task, (err) ->
    return callback(err) if err
    console.log '  down'.green, name.grey
    callback null

mms = module.exports

mms.version = pkg.version

mms.create = (name, callback) ->
  timestamp = Date.now()
  file = path.join config.dir, "#{timestamp}-#{name}#{ext}"
  mkdirp.sync dir
  fs.writeFileSync file, template
  console.log '  create'.cyan, file.grey

mms.migrate = (name, callback = ->) ->
  async.eachSeries _loadTasks(), _up, (err) ->
    if err
      console.error err.toString()
    else
      console.log '  complete'.cyan
    callback err

mms.rollback = (name, callback = ->) ->
  async.eachSeries _loadTasks(), _down, (err) ->
    if err
      console.error err.toString()
    else
      console.log '  complete'.cyan
    callback err

mms.status = (callback = ->) ->
  tasks = _loadTasks()
  schema = _loadSchema()
  tasks.forEach (task) ->
    {name} = task
    if schema[name]
      console.log '  up'.green, name.grey
    else
      console.log '  down'.red, name.grey
  callback()
