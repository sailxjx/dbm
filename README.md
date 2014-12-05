MMS [![NPM version][npm-image]][npm-url] [![Build Status][travis-image]][travis-url]
===
Migration with Mongo Shell

# Commands
* `create`
* `migrate`
* `rollback`
* `status`

# Changelog

## 0.1.6
- use temporary file to store mongo shell script

## 0.1.5
- rollback the last step when migrate failed

## 0.1.1 ~ 0.1.3
- add env variables in configuation and change the schema structure

## 0.1
- use `mongo` function to execute mongo shell
- replace `async` with `bluebird`
- support node v0.11 execSync

# License
MIT

[npm-url]: https://npmjs.org/package/mms
[npm-image]: http://img.shields.io/npm/v/mms.svg

[travis-url]: https://travis-ci.org/sailxjx/mms
[travis-image]: http://img.shields.io/travis/sailxjx/mms.svg
