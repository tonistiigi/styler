os = require 'os'
{fork} = require 'child_process'

numWorkers = Math.min os.cpus().length, 4
workers = []
callbacks = {}
cycle = 0

onMessage = ({callbackId, response}) ->
  if {task, cb} = callbacks[callbackId]
    if task == 'renderStylus'
      cb response.err, response.css, response.imports
    else if task == 'getStylusOutline'
      cb response.nodes, response.css
    delete callbacks[callbackId]
    
makeWorker = ->
  worker = fork __dirname + '/stylus_worker'
  worker.on "message", onMessage

callWorker = (name, params, cb) ->
  if workers.length <= cycle
    worker = makeWorker()
    workers.push worker
  else
    worker = workers[cycle]
  
  cycle++
  cycle = 0 if cycle >= numWorkers
  
  params.task = name
  params.callbackId = ~~ (Math.random() * 1e9)
  callbacks[params.callbackId] = params
  params.cb = cb
  worker.send params

exports.getStylusOutline = (options, cb) ->
  callWorker 'getStylusOutline', options: options, cb

exports.renderStylus = (path, data, cb) ->
  callWorker 'renderStylus', path: path, data: data, cb
