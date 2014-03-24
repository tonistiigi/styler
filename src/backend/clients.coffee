fs = require "fs"
{_} = require "underscore"
useragent = require 'useragent'
{Projects, Clients, Settings} = require "./data"
{isAllowedIP} = require './utils'
log = require './log'
io = global.io

# Call an async method in client's side.
exports.callClient = (clientId, method, params={}, cb=->) ->
  client = Clients.get clientId
  if method == 'focus'
    id = (params.title || clientId)
    io.of('/info').emit 'focus', id
  else
    client?.socket?.emit "callclient", method, params, (response) -> cb response

# Returns keyboard shortcuts that are also sent to client side.
getKeyCommands = ->
  keyboard_shortcuts = Settings.at(0).get "keyboard_shortcuts"
  keys = {}
  for key in ["toggle-window-mode", "start-inspector-mode", "toggle-iframe-container"]
    keys[key] = keyboard_shortcuts[key].export
  keys

# Info namespace is used in extensions to detect if daemon is running.
io.of("/info").on 'connection', (socket) ->
  return socket.disconnect() unless isAllowedIP global.allowed, socket.handshake.address.address
  # Check if url is part of some project.
  socket.on 'checkproject', (url, cb) ->
    cb !!Projects.find (p) -> 0 == url.indexOf p.get("baseurl")

# Client connection handler.
io.of("/clients").on 'connection', (socket) ->
  return socket.disconnect() unless isAllowedIP global.allowed, socket.handshake.address.address
  client = null
  
  onClientRegistred = (_client) ->
    client = _client
    client.socket = socket
    socket.emit 'registered', client.id, client.get('session_id'), getKeyCommands()
    projectId = client.get "project"
    if projectId
      sendBaseURL = -> socket.emit 'baseurl', Projects.get(projectId).get 'baseurl'
      Projects.get(projectId).bind 'change:baseurl', sendBaseURL
      sendBaseURL()
    log.info id: client.id, project: projectId, url: client.get 'url', 'Client connected'
  
  socket.on "register", (info) ->
    projectId = 0
    if info.url?
      project = Projects.find (project) -> (info.url.indexOf project.get 'baseurl') == 0
      projectId = project.id if project
    
    (require "./console").getConsole projectId if projectId

    sessionId = parseInt info.sessionId, 10
    client = Clients.find (o) -> o.get('session_id') == sessionId

    if client  
      if client.get("project") != projectId || client.get("connected")
        client = null
        sessionId = ~~ (Math.random() * 1e8)

    agent = useragent.parse info.useragent
    agenttype = switch (agent.family.split " ")[0].toLowerCase()
      when "chrome" then "chrome"
      when "firefox" then "firefox"
      when "safari" then "safari"
      when "opera" then "opera"
      when "ie" then "ie"
      when "ipad" then "ipad"
      when "iphone", "ipod" then "iphone"
      when "android" then "android"
      when "blackberry" then "blackberry"
      else "unknown"

    clientData =
      name: info.name
      project: projectId
      session_id: sessionId
      url: info.url
      useragent: agent.toString()
      css: info.css
      embed: info.embed
      connected: true
      agenttype: agenttype
      lastTime: (new Date()).getTime()

    if client
      clearTimeout client._clientRemoveTimeout
      client.save clientData, success: onClientRegistred, wait: true
    else
      Clients.create clientData, success: onClientRegistred, wait: true

  socket.on "change:stylesheets", (stylesheets) ->
    return unless client
    current = client.get "css"
    client.save css: current.concat (sheet for sheet in stylesheets)

  #direct messages from the page. like inspect started with keyboard shortcut
  socket.on "clientmessage", (name, params) ->
    return unless client
    projectId = client.get('project')
    (require "./console").getConsole(projectId)?.onClientMessage name, params
    
  socket.on "disconnect", ->
    return unless client
    client.save connected: false
    client._clientRemoveTimeout = setTimeout (-> client.destroy()), 4e3
    log.debug id: client.id, 'Client disconnected'
