pkg = require '../package.json'
mms = require './mms'

usage = """

  Usage: mms [command]

  Commands:

    migrate    [name|version|step]    migrate to the given migration (default)
    rollback   [name|version|step]    rollback till given migration
    create     [name]                 create a new migration file with its name

"""

switch process.argv[2]
  when '-h', '--help' then console.log usage
  when '-v', '--version' then console.log pkg.name + " " + pkg.version
  when 'migrate' then mms.migrate process.argv[3]
  when 'rollback' then mms.rollback process.argv[3]
  when 'create' then mms.create process.argv[3]
  when undefined then mms.migrate()
  else
    console.log "Unknown command #{process.argv[2]}"
    console.log usage
