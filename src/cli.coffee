commander = require 'commander'
pkg = require '../package.json'
mms = require './mms'

commander.version pkg.version
  .usage '[command] [options]'

commander.command 'migrate'
  .usage '[name|version|step]'
  .description '(default) migrate to the given migration'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.migrate name, process.exit

commander.command 'rollback'
  .usage '[name|version|step]'
  .description 'rollback till given migration'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.rollback name, process.exit

commander.command 'create'
  .usage '[name]'
  .description 'create a new migration file with its name'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.create name, process.exit

commander.command 'status'
  .description 'show status of migrations'
  .action -> mms.status process.exit

args = commander.parse process.argv

mms.migrate null, process.exit if args.args.length < 1
