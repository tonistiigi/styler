var os = require('os')
var bunyan = require('bunyan')
var config = require('./config').logger
var argv = require('optimist').argv

var streams = [config]

if (argv.log) {
  streams.push({
    stream: process.stdout,
    level: argv.log
  })
}

if (config && config.type === 'rotating-file') {
  require('mkdirp').sync(require('path').dirname(config.path))
}

var logger = module.exports = bunyan.createLogger({
  name: require('../../package').name,
  streams: streams,
  serializers: bunyan.stdSerializers
})

module.exports = logger

logger.info({
  title: process.title,
  version: process.version,
  argv: process.argv,
  arch: process.arch,
  platform: process.platform
}, 'process started')

/*
process.on('SIGINT', function() {
  logger.debug('process interrupted')
  process.exit(0)
})
*/

process.on('uncaughtException', onUncaughtException)
setInterval(logProcessInfo, config.processLogInterval)


function onUncaughtException(err) {
  logger.error(err, 'uncaught Exception')
  console.log('uncaught Exception:', err)
  console.log(err.stack)
  process.abort()
}

function logProcessInfo() {
  var memoryUsage = process.memoryUsage()
  logger.debug({
    rss: memoryUsage.rss,
    heapTotal: memoryUsage.heapTotal,
    heapUsed: memoryUsage.heapUsed,
    uptime: process.uptime(),
    ostotalmem: os.totalmem(),
    osfreemem: os.freemem(),
    osloadavg: os.loadavg(),
    osuptime: os.uptime()
  }, 'process info')
}