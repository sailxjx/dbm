process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
{exec} = require 'child_process'
mms = require '../src/mms'

Promise.promisifyAll fs

describe 'Create', ->

  before (done) -> exec '''
  mongo 127.0.0.1/test --eval 'db.dropDatabase();'
  ''', done

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
