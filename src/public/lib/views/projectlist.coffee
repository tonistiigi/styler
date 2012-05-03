define (require, exports, module) ->
  ProjectView = require 'lib/views/project'

  ProjectListView = Backbone.View.extend
    id: 'project-list-view'

    initialize: ->
      @collection.on 'add',    @addOne, @
      @collection.on 'reset',  @addAll, @
      @collection.on 'all',    @render, @
      @addAll()

    addOne: (model) ->
      view = new ProjectView model: model
      @$el.append view.render().el

    addAll: ->
      @collection.each @addOne, @

  module.exports = ProjectListView
