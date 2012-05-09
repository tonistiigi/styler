define (require, exports, module) ->
  require 'vendor/link!css/main.css'
  
  ProjectListView = require "lib/views/projectlist"

  MainView = Backbone.View.extend
    template: require "lib/templates/main"

    className: "fpage"
    
    events:
      "click .instructions-opener" : "openInstructions"

    initialize: ->
      @plv = new ProjectListView collection: app.Projects
      app.Projects.on "add", @render, @
      app.Projects.on "reset", @render, @
      app.Projects.on "remove", @render, @

    openInstructions: ->
      @$('.instructions-opener').removeClass 'visible'
      @$('.instructions-container').addClass 'visible'

    render: ->
      @$el.html @template num_projects: app.Projects.length
      @$('.projects-list').append @plv.render().el
      bookmark = @$(".bookmarklet")[0]
      if bookmark
        bookmark_source = require "vendor/text!lib/bookmarklet.js"
        bookmark_source = bookmark_source.replace /\/\/.*$/mi, ''
        bookmark_source = bookmark_source.replace "#origin", window.location.protocol + '//' + window.location.host
        bookmark.setAttribute "href", "javascript:" + bookmark_source
      inject = @$(".injected_code")[0]
      if inject
        inject.innerHTML = '<script type="text/javascript" src="' + window.location.protocol + '//' + window.location.host +  '/styler.js"></script>'
      @$('.instructions-opener').toggleClass 'visible', !!app.Projects.size()
      @$('.instructions-container').toggleClass 'visible', !app.Projects.size()

      @

  module.exports = MainView
