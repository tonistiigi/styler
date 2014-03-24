{join} = require "path"
{existsSync, writeFileSync} = require "fs"

{_} = require 'underscore'
Backbone = require 'backbone'
require './../public/lib/backbone-socketio'
jsonstore = require "./json-store"
io = require "socket.io"

jsonstore.file = join global.homeDir, 'db.json'
writeFileSync jsonstore.file, "{}" unless existsSync jsonstore.file
storage = jsonstore.read()

Backbone.connector = backends: {}
  
Backbone.connector.addClient = (socket) ->
  socket.on "serverSync", Backbone.serverSync
  socket.join "backbone"

Backbone.connector.connect = (collection, store) ->
  Backbone.connector.backends[collection.backend] = new Backbone.Backend (if store then collection.backend else null)

# register server side callback
Backbone.serverSync = (method, name, model, options, success) ->
  action = if options.action? then options.action else method

  Backbone.connector.backends[name][action] model, options, (data) =>
    if method == "read"
      success(data, options)
    else
      try
        Backbone.syncCallback name, method, data, options
      catch e
        console.log e
      success(data, options)
      global.io.of('/console').in('backbone').emit 'BackboneSync', name, method, data, options

class Backbone.Backend
  constructor: (@storage_name="")->
    @col = []
    if @storage_name
      @col = storage[@storage_name] or []
  writeStorage: ->
    if @storage_name
      storage[@storage_name] = @col
      jsonstore.save(storage);
  update: (data, options, callback) ->
    for el, i in @.col
      if data.id == el.id
        @col[i] = data
        callback?(@col[i])
        @writeStorage()
        return @col[i]
  create: (data, options, callback) ->
    data.id = Math.floor(Math.random() * 1e7);
    @.col.push(data)
    callback?(data)
    @writeStorage()
  read: (data, options, callback) ->
    if data?.id?
      item = _(@.col).detect (item) -> item.id == data.id
      callback?(item)
    else
      callback?(@col)
  delete: (data, options, callback) ->
    for el, i in @.col
      if data.id == el.id
        @.col.splice(i, 1);
        callback?(data)
        @writeStorage()
        return data

Backbone.Backend.extend = Backbone.Model.extend
module.exports = Backbone
