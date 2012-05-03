define (require, exports, module) ->
  ClientListView = require 'lib/views/clientlist'

  ProjectView = Backbone.View.extend

    template: require 'lib/templates/project_item'

    events:
      'click .btn.delete': 'delete'
      'click .btn.edit': 'edit'
      'click .expand': 'expand'
      'click .num-clients': 'expand'
      'click .btn.projectlaunch': 'open'

    initialize: ->
      @model.on 'change', @render, @
      @model.on 'remove', @remove, @
      @model.on 'clients:add', @render, @
      @model.on 'clients:remove', @render, @
      @clientsView = new ClientListView project: @model

    render: ->
      @$el.html @template _.extend @model.toJSON(),
        isActive: @model.isActive
        clientCount: @model.getClients().length
      @$('.clients')?.append @clientsView.el
      @

    open: ->
      clients = @model.getClients()
      url = if clients.length then clients[0].get('session_id') else @model.id
      app.router.navigate '' + url, trigger: true

    delete: ->
      if confirm "Are you sure you wish to delete project #{@model.get('name')}?"
        _.each @model.getClients(), (client) -> client.save project: 0
        @model.destroy()

    edit: -> 
      app.router.navigate 'edit/' + @model.id, trigger: true

    expand: ->
      app.router.navigate 'project/' + @model.id, trigger: true

  module.exports = ProjectView