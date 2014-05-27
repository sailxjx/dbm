class MMS

  # Create new migration files
  create: (file, callback = ->) ->

  # Start migration
  migrate: (name, callback = ->) ->

  # Rollback to the former version
  rollback: (name, callback = ->) ->

module.exports = new MMS
