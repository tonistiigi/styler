define (require, exports, module) ->

  ClientView = Backbone.View.extend

    template: require 'lib/templates/output_item'

    events:
      'click .btn.launch' : 'open'

    initialize: ->
      @model.on 'change', @render, @
      @model.on 'remove', @remove, @

    open: ->
      app.router.navigate '' + @model.get('session_id'), trigger: true

    render: ->
      @$el.html @template @model.toJSON()
      @

  module.exports = ClientView