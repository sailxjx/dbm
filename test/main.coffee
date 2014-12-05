process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
{exec} = require 'child_process'
util = require 'util'
mms = require '../src/mms'
config = require '../src/config'
config = util._extend config, require('./config')

Promise.promisifyAll fs

_dropDatabase = (done) -> exec '''
  mongo 127.0.0.1/test --eval 'db.dropDatabase();'
  ''', done

before _dropDatabase

describe 'Create', ->

  it 'should create tmp migration file', (done) ->
    mms.create 'tmp-file'

    .then -> fs.readdirAsync './migrations'

    .then (files) ->

      files.some (file) -> file.match /^[0-9]{13}-tmp-file/
      .should.eql true

      done()

    .catch done

  after (done) ->

    fs.readdirAsync './migrations'

    .each (file) -> fs.unlinkAsync path.join('migrations', file) if file.indexOf('tmp-file') > 0

    .then -> done()

    .catch done

describe 'Migrate', ->

  it 'should migrate till the create-user migration', (done) ->

    mms.migrate 'create-user'

    .then ->

      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      print(db.users.findOne().email);
      '
      ''', (err, stdout) ->
        stdout.should.containEql 'mms@gmail.com\n'
        done()

    .catch done

  it 'should migrate till the last migration', (done) ->

    mms.migrate()

    .then ->

      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      print(db.users.findOne().email);
      '
      ''', (err, stdout) ->
        stdout.should.containEql 'mms@icloud.com\n'
        done err

    .catch done

describe 'Rollback', ->

  it 'should rollback 1 step', (done) ->

    mms.rollback(1)

    .then ->

      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      print(db.users.findOne().email);
      '
      ''', (err, stdout) ->
        stdout.should.containEql 'mms@gmail.com\n'
        done()

    .catch done

  after (done) ->

    fs.unlink 'migrations/.migrate.json', done

describe 'Migrate&Rollback', ->

  before (done) ->
    # Prepare the error migrate
    fs.writeFile "migrations/1315517929762-error-user.coffee", """
    # Save the user but throw an error
    exports.up = (next) ->
      mongo -> db.users.save({name: 'wrong'})
      next(new Error("SOMETHINE WRONG"))

    exports.down = (next) ->
      mongo -> db.users.remove({name: 'wrong'})
      next()
    """, done


  it 'should rollback the last step when migrate failed', (done) ->
    mms.migrate()

    .then (err) ->

      return done(new Error('MISSING ERROR OBJECT')) unless err

      err.message.should.eql "SOMETHINE WRONG"
      exec '''
      mongo 127.0.0.1/text --quiet --eval '
      print(db.users.findOne({name: "wrong"}));
      '
      ''', (err, stdout) ->
        stdout.should.eql 'null\n'
        done()

    .catch done

  after (done) ->
    fs.unlink "migrations/1315517929762-error-user.coffee", done

describe 'MongoCommand', ->

  it 'should succeed for the right script', ->
    mongo -> db.users.findOne()

  it 'should fail for the error script', ->
    try
      mongo -> db.user.findOneAndUpdate({}, {})  # mongo shell do not have this command
    catch err

    throw new Error('MISS EXCEPTION') unless err

after _dropDatabase
