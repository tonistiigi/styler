#!/usr/bin/env node

var path = require('path')
var parse = require('url').parse

var config = module.exports = require('rc')(
  require('../../package').name.replace(/-/g, '_'),
  require('path').join(__dirname, '../../', 'defaults.json'))


if (config.logger && config.logger.count) {
  config.logger.count = parseInt(config.logger.count)
}
if (config.logger && config.logger.path) {
  config.logger.path = abspath(config.logger.path)
}
if (config.logger) {
  config.logger.processLogInterval = parseInt(config.logger.processLogInterval) || 9e5
}


function abspath(v) {
  return v[0] === '.' ? path.join(__dirname, '../..', v) : v
}

if (!module.parent) {
  console.log(config)
}