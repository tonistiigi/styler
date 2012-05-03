require.config
  baseUrl: '/'
  paths:
    'lib/views/console': 'build/editor'
    'lib/views/editor' : 'build/editor'
    'lib/editor/autocompleter' : 'build/editor-defer'
    'lib/views/ui/completer': 'build/editor-defer'
    'lib/views/commandline': 'build/editor-defer'
    'lib/views/ui/search': 'build/editor-defer'
    'lib/editor/mousecommands': 'build/editor-defer'
    'lib/editor/statsmanager': 'build/editor-defer'
    'lib/views/newproject': 'build/newproject'
    'lib/views/ui/popup': 'build/editor-optional'
    'vendor/colorpicker': 'build/editor-optional'
    'lib/views/ui/imagepreview': 'build/editor-optional'
    'lib/views/ui/infotip': 'build/editor-optional'
    'lib/views/settings': 'build/settings'
    'lib/editor/stylus': 'build/mode-stylus'
    'lib/editor/css': 'build/mode-css'

tm1 = +new Date()
window.tm = (name) ->
  #console.log 'time', name, new Date() - tm1
  
window.app = {} unless window.app
require ['lib/models', 'lib/router', 'lib/views/app'], (Models, Router, AppView) ->
  tm('loaded')
  $ ->
    tm('domload')
    app.Clients   = new Models.ClientList 
    app.Projects  = new Models.ProjectList null, clients: app.Clients
    app.router    = new Router
    app.app       = new AppView
    $('#page_loader').remove()
    app.app.launch()
