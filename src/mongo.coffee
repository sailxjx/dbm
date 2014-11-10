###*
 * execute mongo shell script
 * @param  {Object}   options The options
 * @param  {Function} fn      The function executed in mongo shell
 * @return {Number}           Exit code
###
{execSync} = require 'child_process'

# For node 0.11
if typeof execSync is 'function'
  run = execSync
else
  {run} = require 'execSync'

module.exports = (options, fn) ->

  if arguments.length is 1
    fn = options
    options = {}

  {db} = options
  db or= ''

  code = run """
  mongo #{db} <<EOF
  (#{fn.toString()})();
  EOF
  """.replace /\$/mg, '\\$'

  if toString.call(code) is '[object Number]' and code isnt 0 then throw new Error("ERROR: #{code}") else null
