if module?.exports
  {_} = require 'underscore'
  Backbone = require 'backbone'
else
  {_, Backbone} = this

Backbone.syncCallback = (name, method, data, options) ->
  return unless Backbone.Collection["_listeners_#{name}"]
  for collection in Backbone.Collection["_listeners_#{name}"]
    collection['_' + method](data, options)

class Backbone.Model extends Backbone.Model
  getBackend: ->
    @backend || @collection?.backend

class Backbone.Collection extends Backbone.Collection
  constructor: (models, options) ->
    @backend = options.backend if options?.backend
    super models, options
    @listen() if @backend

  getBackend: ->
    @backend

  notify:
    all: ->
      true
    none: ->
      false
    self: (clientId, options) ->
      clientId is options?.clientId
    others: (clientId, options) ->
      clientId isnt options?.clientId

  _update: (model, options) ->
    if @notify[options.notify](@clientId, options)
      @get(model.id)?.set(model, options) if model?
  _create: (model, options) ->
    if @notify[options.notify](@clientId, options)
      @add(model, options) if model?
  _delete: (model, options) ->
    if @notify[options.notify](@clientId, options)
      @remove(model, options) if model?
  _read: (data, options, success) ->
    #@[if options?.add then 'add' else 'reset'](data, options);

  listen: ->
    @clientId = ~~ (Math.random() * 10e6)
    name = @backend
    lname = "_listeners_#{name}"
    Backbone.Collection[lname] = [] unless Backbone.Collection[lname]
    Backbone.Collection[lname].push this

Backbone.sync = (method, model, options) ->
  backend = model?.getBackend?()
  return unless backend
  success = options.success
  # nowjs currently doesn't seem to handle complex
  # structures so removing callbacks for now
  delete options.success
  delete options.error

  # include clientId if skip is present
  options.notify = 'others' unless options.notify?
  options.clientId = model.collection?.clientId

  try
    if module?
      Backbone.serverSync method, backend, model.attributes, options, success
    else
      app.socket.emit 'serverSync', method, backend, model.attributes, options, success
  catch e
    model.trigger('error', model, e, options)
