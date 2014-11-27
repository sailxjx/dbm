commander = require 'commander'
pkg = require '../package.json'
mms = require './mms'

_exit = (err) ->
  code = if err then err.code or 1 else 0
  process.exit code

commander.version pkg.version
  .usage '[command] [options]'

commander.command 'migrate'
  .usage '[name|version|step]'
  .description '(default) migrate to the given migration'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.migrate name, _exit

commander.command 'rollback'
  .usage '[name|version|step]'
  .description 'rollback till given migration'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.rollback name, _exit

commander.command 'create'
  .usage '[name]'
  .description 'create a new migration file with its name'
  .action (name, options) ->
    name = null if arguments.length is 1
    mms.create name, _exit

commander.command 'status'
  .description 'show status of migrations'
  .action -> mms.status _exit

args = commander.parse process.argv

mms.migrate null, _exit if args.args.length < 1
