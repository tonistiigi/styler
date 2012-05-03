define (require, exports, module) ->

  Router = Backbone.Router.extend
    routes:
      '' : 'main'
      'project/:project' : 'project'
      'edit/:project' : 'edit'
      ':clientId' : 'console'

    # Front page with no projects selected.
    main: ->
      app.console?.destroy()
      app.Projects.setActive 0
      app.app.openMain()

    # Front page with one project extended.
    project: (projectid) ->
      app.console?.destroy()
      app.Projects.setActive projectid
      app.app.openMain()

    # Console view
    console: (clientId) ->
      app.app.openConsole parseInt clientId, 10

    edit: (projectId) ->
      app.app.editProject parseInt projectId, 10

  module.exports = Router