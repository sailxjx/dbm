commander = require 'commander'
pkg = require '../package.json'
mms = require './mms'

commander.version pkg.version
  .usage '[options] [command]'
  .option '--ext <ext>', 'extension of migration files'
  .option '--db <db>', 'connection of migration db'
  .option '--dir <dir>', 'directory for saving migration files'
  .option '--schema <schema>', 'the schema file to saving migration status'

commander.command 'migrate'
  .usage '[name|version|step]'
  .description '(default) migrate to the given migration'
  .action (name, options) ->
    if arguments.length < 2
      options = name
      name = null
    mms.migrate name, options.parent

commander.command 'rollback'
  .usage '[name|version|step]'
  .description 'rollback till given migration'
  .action (name, options) ->
    if arguments.length < 2
      options = name
      name = '1'
    mms.rollback name, options.parent

commander.command 'create'
  .usage '[name]'
  .description 'create a new migration file with its name'
  .action (name, options) ->
    if arguments.length < 2
      return console.error '  fail'.red, "missing name".grey
    mms.create name, options.parent

commander.command 'status'
  .description 'show status of migrations'
  .action (options) -> mms.status()

commander.parse process.argv
