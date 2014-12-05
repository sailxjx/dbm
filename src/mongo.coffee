###*
 * execute mongo shell script
 * @param  {Object}   options The options
 * @param  {Function} fn      The function executed in mongo shell
 * @return {Number}           Exit code
###
{execSync} = require 'child_process'
path = require 'path'
fs = require 'fs'
config = require './config'

# For node 0.11
if typeof execSync is 'function'
  run = execSync
else
  {run} = require 'execSync'

module.exports = (options, fn) ->

  if arguments.length is 1
    fn = options
    options = {}

  tmpDir = config.tmpDir or '/tmp'
  tmpFileName = path.join(tmpDir, "migration_" + Date.now() + '.js')

  fs.writeFileSync tmpFileName, "(#{fn.toString()})();"

  {db} = options
  db or= config.db or ''

  code = run "mongo #{db} #{tmpFileName}"

  fs.unlinkSync tmpFileName

  if toString.call(code) is '[object Number]' and code isnt 0 then throw new Error("ERROR: #{code}") else null
