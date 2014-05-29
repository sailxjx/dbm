process.chdir __dirname

should = require 'should'
fs = require 'fs'
path = require 'path'
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

