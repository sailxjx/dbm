// Generated by CoffeeScript 1.7.1
(function() {
  var MMS, config, fs, logger, mkdirp, path, util;

  fs = require('fs');

  path = require('path');

  util = require('util');

  mkdirp = require('mkdirp');

  config = require('./config');

  logger = require('./logger');

  MMS = (function() {
    function MMS() {
      this._loadrc();
    }

    MMS.prototype._loadrc = function() {
      var e;
      try {
        return config = util._extend(config, require(path.resolve('./.mmsrc.json')));
      } catch (_error) {
        e = _error;
        return console.log(e);
      }
    };

    MMS.prototype._loadMigrations = function() {};

    MMS.prototype.create = function(name, callback) {
      var downFile, ext, timestamp, upFile;
      if (callback == null) {
        callback = function() {};
      }
      timestamp = Date.now();
      ext = config.ext || '.js';
      if (config.compiler === 'coffee') {
        ext = '.coffee';
      }
      upFile = path.join(config.dir, "" + timestamp + "_up_" + name + ext);
      downFile = path.join(config.dir, "" + timestamp + "_down_" + name + ext);
      mkdirp.sync(config.dir);
      fs.writeFileSync(upFile, '');
      logger.info('create up file:', upFile);
      fs.writeFileSync(downFile, '');
      logger.info('create down file:', downFile);
      return callback();
    };

    MMS.prototype.migrate = function(name, callback) {
      if (callback == null) {
        callback = function() {};
      }
    };

    MMS.prototype.rollback = function(name, callback) {
      if (callback == null) {
        callback = function() {};
      }
    };

    return MMS;

  })();

  module.exports = new MMS;

}).call(this);