process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
mms = require '../lib/mms.js'
config = require '../lib/config.js'

# describe 'Create', ->

#   it 'should create two migration files', (done) ->
#     mms.create 'tmp_file', {}, ->
#       files = fs.readdirSync './migrations'
#       hasUp = false
#       hasDown = false
#       for file in files
#         hasUp = true if file.match /^[0-9]{13}_up_tmp_file\.js$/
#         hasDown = true if file.match /^[0-9]{13}_down_tmp_file\.js$/
#       hasUp.should.eql true
#       hasDown.should.eql true
#       done()

#   it 'should create two coffee script file when use coffee compiler', (done) ->
#     config.ext = '.coffee'
#     mms.create 'tmp_file', {}, ->
#       files = fs.readdirSync './migrations'
#       hasUp = false
#       hasDown = false
#       for file in files
#         hasUp = true if file.match /^[0-9]{13}_up_tmp_file\.coffee$/
#         hasDown = true if file.match /^[0-9]{13}_down_tmp_file\.coffee$/
#       hasUp.should.eql true
#       hasDown.should.eql true
#       delete config.ext
#       done()

#   after ->
#     files = fs.readdirSync './migrations'
#     for file in files
#       if file.indexOf('tmp_file') > 0
#         fs.unlinkSync path.join('migrations', file)

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
