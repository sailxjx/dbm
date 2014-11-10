###*
 * execute mongo shell script
 * @param  {Object}   options The options
 * @param  {Function} fn      The function executed in mongo shell
 * @return {Number}           Exit code
###
module.exports = (options, fn) ->
  {run} = require 'execSync'

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

  if code then throw new Error("ERROR: #{code}") else null
