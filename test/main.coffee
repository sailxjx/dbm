process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
{exec, run} = require 'execSync'
mms = require '../src/mms'

Promise.promisifyAll fs

describe 'Create', ->

  before -> run '''
  mongo 127.0.0.1/test --eval 'db.dropDatabase();'
  '''

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

# describe 'Migrate', ->

#   it 'should migrate till the create-user migration', ->
#     mms.migrate 'create-user'
#     {stdout} = exec '''
#     mongo 127.0.0.1/test --quiet --eval '
#     print(db.users.findOne().email);
#     '
#     '''
#     stdout.should.containEql 'mms@gmail.com\n'

# describe 'Migrate', ->

#   it 'should migrate till the create_user migration', (done) ->
#     mms.migrate 'create_user', {}, (err) ->
#       exec '''
#       mongo 127.0.0.1/test --quiet --eval '
#       var user = db.users.findOne();
#       print(user.email);
#       '
#       ''', (err, stdout) ->
#         stdout.should.eql 'user@gmail.com\n'
#         delete require.cache[path.resolve('./migrations/.migrate.json')]
#         done err

#   it 'should migrate till the 1401332571122(update_email) migration', (done) ->
#     mms.migrate '1401332571122', {}, (err) ->
#       exec '''
#       mongo 127.0.0.1/test --quiet --eval '
#       var user = db.users.findOne();
#       print(user.email);
#       '
#       ''', (err, stdout) ->
#         stdout.should.eql 'new@gmail.com\n'
#         delete require.cache[path.resolve('./migrations/.migrate.json')]
#         done err

#   it 'should migrate the next migration', (done) ->
#     mms.migrate '1', {}, (err) ->
#       exec '''
#       mongo 127.0.0.1/test --quiet --eval '
#       var user = db.users.findOne();
#       print(user.avatar);
#       '
#       ''', (err, stdout) ->
#         stdout.should.eql 'avatarurl\n'
#         delete require.cache[path.resolve('./migrations/.migrate.json')]
#         done err

#   it 'should update the migration file', ->
#     schema = require path.resolve('./migrations/.migrate.json')
#     Object.keys(schema).length.should.eql 3
#     delete require.cache[path.resolve('./migrations/.migrate.json')]

#   after (done) ->
#     fs.unlinkSync path.resolve './migrations/.migrate.json'
#     exec '''
#     mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
#     ''', done

# describe 'Rollback', ->

#   before (done) -> mms.migrate null, {}, done

#   it 'should rollback 1 migration', (done) ->
#     mms.rollback '1', {}, (err) ->
#       exec '''
#       mongo 127.0.0.1/test --quiet --eval '
#       var user = db.users.findOne();
#       print(user.avatar);
#       '
#       ''', (err, stdout) ->
#         stdout.should.eql 'null\n'
#         delete require.cache[path.resolve('./migrations/.migrate.json')]
#         done err

#   it 'should rollback to update_email', (done) ->
#     mms.rollback 'update_email', {}, (err) ->
#       exec '''
#       mongo 127.0.0.1/test --quiet --eval '
#       var user = db.users.findOne();
#       print(user.email);
#       '
#       ''', (err, stdout) ->
#         stdout.should.eql 'user@gmail.com\n'
#         delete require.cache[path.resolve('./migrations/.migrate.json')]
#         done err

#   after (done) ->
#     fs.unlinkSync path.resolve './migrations/.migrate.json'
#     exec '''
#     mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
#     ''', done

# describe 'Status', ->

#   before (done) -> mms.migrate null, {}, done

#   it 'need all status to be up', (done) ->
#     mms.status (err, status) ->
#       for title, _status of status
#         _status.should.eql 'up'
#       done()

#   it 'should set down last migration when use rollback', (done) ->
#     mms.rollback '1', {}, ->
#       mms.status (err, status) ->
#         for title, _status of status
#           if title is '1401333214163_add_avatar'
#             _status.should.eql 'down'
#           else
#             _status.should.eql 'up'
#         done()

#   after (done) ->
#     fs.unlinkSync path.resolve './migrations/.migrate.json'
#     exec '''
#     mongo 127.0.0.1/test --quiet --eval 'db.dropDatabase();'
#     ''', done
