require.config
  baseUrl: '/'
  #paths:

tm1 = +new Date()
window.tm = (name) ->
  console.log 'time', name, new Date() - tm1

class Lock
  constructor: -> @count = 0
  await: (f) ->
    @count++
    f => @defer?() unless --@count

lock = new Lock()

lock.await (cb) ->
  require ['vendor/underscore'], -> require ['vendor/backbone'], ->
    require ['lib/backbone-socketio'], cb

lock.await (cb) ->
  require ['vendor/zepto', 'socket.io/socket.io'], cb

lock.defer = ->
  tm('defer')
  window.app = {} unless window.app
  require ['lib/models', 'lib/router', 'lib/views/app'], (Models, Router, AppView) -> $ ->
    app.Clients   = new Models.ClientList
    app.Projects  = new Models.ProjectList null, clients: app.Clients
    app.router    = new Router
    app.app       = new AppView
    $('#page_loader').remove()
    app.app.launch()
