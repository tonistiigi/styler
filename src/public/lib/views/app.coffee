define (require, exports, module) ->
  require 'vendor/link!css/app.css'

  MainView = require 'lib/views/main'
  {SettingsList, Settings} = require 'lib/models'

  AppView = Backbone.View.extend

    initialize: ->
      @setElement document.body

    $: (cb) ->
      return cb() if @_ioLoaded
      @_cbQueue = [] unless @_cbQueue
      @_cbQueue.push cb
      
    launch: ->
      unless (window.sessionStorage.getItem('_ignore_agent') == '1') or @isSupportedAgent()
        require ['lib/views/warning-screen'], (WarningScreen) =>
          new WarningScreen name: 'warning_browser'
        return
      
      app.Projects.reset __data.projects
      app.Clients.reset __data.clients
      settings = new SettingsList
      settings.reset __data.settings
      app.Settings = settings.at(0)

      blank = new Settings().toJSON()
      newopt = {}
      _.each blank, (v, k) ->
        newopt[k] = v unless app.Settings.get(k)? #todo: use reduce
      app.Settings.save newopt if _.size newopt

      # Add new keyboard shortcuts.
      keys = app.Settings.get 'keyboard_shortcuts'
      didadd = false
      for k, v of blank.keyboard_shortcuts
        unless keys[k]
          keys[k] = v
          didadd = true
      if didadd
        app.Settings.save keyboard_shortcuts: keys
    
      # Disable sync to avoid disconnecting on 'Unsaved file' dialog.
      
      #app.socket = io.connect '/console', 'sync disconnect on unload': false
      
      onConnect = =>
        tm('connected')
        _.defer cb for cb in @_cbQueue if @_cbQueue
        @_ioLoaded = true
      if app.socket?.socket?.connected
        onConnect()
      else
        app.socket.on 'connect', onConnect
        
      app.socket.on 'BackboneSync', Backbone.syncCallback

      app.socket.on 'reconnect', ->
        window.location.reload()

      app.socket.on 'disconnect', =>
        _.delay => # No need to show it on refresh.
          app.console?.destroy()
          require ['lib/views/warning-screen'], (WarningScreen) =>
            new WarningScreen name: 'disconnect'
        , 200
    

      app.socket.emit 'getRoot', (r) -> app.root = r
      
      Backbone.history.start pushState: true, root: '/'
      
      _.delay ->
        require ['lib/views/warning-screen'], ->
      , 2500
      

    openMain: ->
      @mainView = new MainView unless @mainView
      @$el.css(backgroundColor: '#fff').empty().append @mainView.render().el
      document.title = 'Styler' # TODO: better name needed!

    loadConsole: (project, client) ->
      if app.console?.el.parentNode && app.console.project.id == project.id
        app.console.loadClient client
      else
        require ['lib/views/console'], (ConsoleView) =>
          view = new ConsoleView project: project, client: client
          @$el.css(backgroundColor: '#333').empty().append view.render().el

    openConsole: (sessionId) ->
      client = app.Clients.find (client) -> client.get('session_id') == sessionId
      if client
        if projectId = client.get 'project'
          @loadConsole app.Projects.get(projectId), client
        else
          require ['lib/views/newproject'], (NewProjectView) => @$ =>
            view = new NewProjectView client: client
            @$el.css(backgroundColor: '#fff').empty().append view.render().el
            window.title = 'New Project'
      else
        if project = app.Projects.get sessionId
          @loadConsole project, null
        else
          app.router.navigate '', trigger: true

    editProject: (projectId) ->
      project = app.Projects.get projectId
      client = project.getClients()[0] || null
      require ['lib/views/newproject'], (NewProjectView) =>
        app.console?.destroy()
        view = new NewProjectView client: client, model: project
        @$el.css(backgroundColor: '#fff').empty().append view.render().el
        window.title = 'Edit project'
        
    showSettings: ->
      require ['lib/views/settings'], (Settings) ->
        new Settings model: app.Settings

    isSupportedAgent: ->
      return true if window.navigator.userAgent.match /webkit/i
      match = window.navigator.userAgent.match /firefox\/([0-9]+)/i
      !!(match && parseInt(match[1], 10) >= 8)

  module.exports = AppView

if window.nativeapp
  window.addEventListener 'keydown', (e) -> 
    if e.keyCode == 82 && e.shiftKey && e.metaKey
      window.location.reload()
  , true
