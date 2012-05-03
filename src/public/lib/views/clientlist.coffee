define (require, exports, module) ->
  ClientView = require 'lib/views/client'

  ClientListView = Backbone.View.extend

    initialize: (opt) ->
      @project = opt.project
      @project.on 'clients:add', @addOne, @
      _.each @project.getClients(), @addOne, @

    addOne: (client) ->
      view = new ClientView model: client
      @$el.append view.render().el

  module.exports = ClientListView