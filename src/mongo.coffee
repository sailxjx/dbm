{run} = require 'execSync'

###*
 * execute mongo shell script
 * @param  {Object}   options The options
 * @param  {Function} fn      The function executed in mongo shell
 * @return {Number}           Exit code
###
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
  """
