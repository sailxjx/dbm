require 'coffee-script/register'
coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
colors = require 'colors'
Promise = require 'bluebird'
Promise.promisifyAll fs

config = require './config'
pkg = require '../package.json'

# Register global functions
global.mongo = require './mongo'

###*
 * Read the global runtime-config file, overwrite the default configuration
###
try
  rcPath = path.join process.env.HOME, '.mmsrc.json'
  config = util._extend config, require rcPath
catch e

{ext, dir} = config

# Load schemas and private configurations
try
  schema = require path.resolve(config.schema)
catch e
  schema = {}

schema.schemas or= {}
schema.config or= {}
config = util._extend config, schema.config
{schemas} = schema

###*
 * Set the env variable by config file
 * The config object is nested with an env key
 * config = {env: {NODE_ENV: 'development'}}
###
Object.keys(config.env or {}).forEach (ek) -> process.env[ek] or= config.env[ek]

###*
 * Migrate template in Coffeescript/Javascript format
 * @type {String}
###
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

###*
 * output infomation
 * @param  {String} action
 * @param  {String} msg
 * @return {Null}
###
_info = (action, msg = '') -> console.log "  #{action}".cyan, msg.grey


###*
 * output error message
 * @param  {Error} error object
 * @return {Null}
###
_error = (err) ->
  console.error "  fail".red, "#{err}".grey
  err

_loadTasks = (direction = 'up') ->
  fs.readdirAsync config.dir

  .then (files) ->

    files.filter (file) -> if file.match /^[0-9]{13}\-.*\.(js|coffee)$/ then true else false

    .sort (x, y) ->
      x = Number(x.split('-')[0])
      y = Number(y.split('-')[0])
      if direction is 'up' then x - y else y - x

    .map (file) -> name: file.split('.')[0], path: path.resolve(path.join(config.dir, file))

_exec = (fn) ->

  if fn.length is 0

    _fn = (next) -> next(null, fn())

  else

    _fn = fn

  Promise.promisify(_fn)()

mms = module.exports

mms.version = pkg.version

mms.create = (name) ->
  timestamp = Date.now()
  file = path.join config.dir, "#{timestamp}-#{name}#{ext}"

  Promise.promisify(mkdirp) dir

  .then (dir) -> fs.writeFileAsync file, template

  .then -> _info 'create', file

  .catch _error

mms.migrate = (name) ->

  stop = false

  _loadTasks('up')

  .reduce (num, task, idx) ->

    return if stop

    migration = require task.path
    throw new Error('INVALID MIGRATION: ' + task.name) unless typeof migration.up is 'function'

    if schemas[task.name]
      _info 'skip', task.name
      return num

    # Execute the migration and save the schema file when finished
    _exec migration.up

    .then ->
      schemas[task.name] = status: 'up'
      # Save schemas
      fs.writeFileAsync config.schema, JSON.stringify schema

    .then ->
      if "#{name}"?.match /^[0-9]{1,2}$/
        stop = true if num is parseInt(name)
      else if task.name.indexOf(name) > -1
        stop = true

      _info 'up', task.name
      num += 1

    .catch (err) ->

      console.error "  error".red, "#{err}".grey

      # If the migration do not have a rollback function, skip
      unless typeof migration.down is 'function'
        err = new Error "migration #{task.name} do not have a rollback function!"
        throw err

      _exec migration.down

      .then ->
        console.log "  rollback".yellow, "#{task.name}".grey
        throw err

  , 1

  .then -> _info 'complete'

  .catch _error

mms.rollback = (name) ->

  name or= 1

  stop = false

  _loadTasks('down')

  .reduce (num, task, idx) ->

    return if stop

    migration = require task.path
    throw new Error('INVALID MIGRATION: ' + task.name) unless typeof migration.down is 'function'
    return _info 'skip', task.name unless schemas[task.name]?.status is 'up'

    _exec migration.down

    .then ->
      delete schemas[task.name]
      fs.writeFileAsync config.schema, JSON.stringify schema

    .then ->
      if "#{name}"?.match /^[0-9]{1,2}$/
        stop = true if num is parseInt(name)
      else if task.name.indexOf(name) > -1
        stop = true

      _info 'down', task.name
      num += 1

  , 1

  .then -> _info 'complete'

  .catch _error

mms.status = ->

  _loadTasks()

  .then (tasks) ->

    tasks.forEach (task) ->
      {name} = task
      if schemas[name]
        console.log "  up".cyan, name.grey
      else
        console.log "  down".red, name.grey

  .catch _error
