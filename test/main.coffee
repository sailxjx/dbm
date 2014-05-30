process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
mms = require '../lib/mms.js'
config = require '../lib/config.js'

describe 'Create', ->

  it 'should create two migration files', (done) ->
    mms.create 'tmp_file', {}, ->
      files = fs.readdirSync './migrations'
      hasUp = false
      hasDown = false
      for file in files
        hasUp = true if file.match /^[0-9]{13}_up_tmp_file\.js$/
        hasDown = true if file.match /^[0-9]{13}_down_tmp_file\.js$/
      hasUp.should.eql true
      hasDown.should.eql true
      done()

  it 'should create two coffee script file when use coffee compiler', (done) ->
    config.ext = '.coffee'
    mms.create 'tmp_file', {}, ->
      files = fs.readdirSync './migrations'
      hasUp = false
      hasDown = false
      for file in files
        hasUp = true if file.match /^[0-9]{13}_up_tmp_file\.coffee$/
        hasDown = true if file.match /^[0-9]{13}_down_tmp_file\.coffee$/
      hasUp.should.eql true
      hasDown.should.eql true
      delete config.ext
      done()

  after ->
    files = fs.readdirSync './migrations'
    for file in files
      if file.indexOf('tmp_file') > 0
        fs.unlinkSync path.join('migrations', file)

describe 'Migrate', ->

  it 'should migrate till the create_user migration', (done) ->
    mms.migrate 'create_user', {}, (err) ->
      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      var user = db.users.findOne();
      print(user.email);
      '
      ''', (err, stdout) ->
        stdout.should.eql 'user@gmail.com\n'
        delete require.cache[path.resolve('./migrations/.migrate.json')]
        done err

  it 'should migrate till the 1401332571122(update_email) migration', (done) ->
    mms.migrate '1401332571122', {}, (err) ->
      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      var user = db.users.findOne();
      print(user.email);
      '
      ''', (err, stdout) ->
        stdout.should.eql 'new@gmail.com\n'
        delete require.cache[path.resolve('./migrations/.migrate.json')]
        done err

  it 'should migrate the next migration', (done) ->
    mms.migrate '1', {}, (err) ->
      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      var user = db.users.findOne();
      print(user.avatar);
      '
      ''', (err, stdout) ->
        stdout.should.eql 'avatarurl\n'
        delete require.cache[path.resolve('./migrations/.migrate.json')]
        done err

  it 'should update the migration file', ->
    schema = require path.resolve('./migrations/.migrate.json')
    Object.keys(schema).length.should.eql 3
    delete require.cache[path.resolve('./migrations/.migrate.json')]

  after (done) ->
    fs.unlinkSync path.resolve './migrations/.migrate.json'
    exec '''
    mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
    ''', done

describe 'Rollback', ->

  before (done) -> mms.migrate null, {}, done

  it 'should rollback 1 migration', (done) ->
    mms.rollback '1', {}, (err) ->
      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      var user = db.users.findOne();
      print(user.avatar);
      '
      ''', (err, stdout) ->
        stdout.should.eql 'null\n'
        delete require.cache[path.resolve('./migrations/.migrate.json')]
        done err

  it 'should rollback to update_email', (done) ->
    mms.rollback 'update_email', {}, (err) ->
      exec '''
      mongo 127.0.0.1/test --quiet --eval '
      var user = db.users.findOne();
      print(user.email);
      '
      ''', (err, stdout) ->
        stdout.should.eql 'user@gmail.com\n'
        delete require.cache[path.resolve('./migrations/.migrate.json')]
        done err

  after (done) ->
    fs.unlinkSync path.resolve './migrations/.migrate.json'
    exec '''
    mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
    ''', done

describe 'Status', ->

  before (done) -> mms.migrate null, {}, done

  it 'need all status to be up', (done) ->
    mms.status (err, status) ->
      for title, _status of status
        _status.should.eql 'up'
      done()

  it 'should set down last migration when use rollback', (done) ->
    mms.rollback '1', {}, ->
      mms.status (err, status) ->
        for title, _status of status
          if title is '1401333214163_add_avatar'
            _status.should.eql 'down'
          else
            _status.should.eql 'up'
        done()

  after (done) ->
    fs.unlinkSync path.resolve './migrations/.migrate.json'
    exec '''
    mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
    ''', done
