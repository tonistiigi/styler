fs = require "fs"
{basename} = require "path"
Backbone = require "backbone"
requirejs = require "requirejs"
{_} = require "underscore"
winston = require 'winston'
{callClient} = require "./clients"
{Clients, Projects} = require "./data"
{getFileLocation, relativeURL, pathIsAllowed} = require "./utils"
{FileList, File, StateList, FoldList, PseudoList} = requirejs "./../public/lib/models"
{watcher} = require "./filewatcher"
stylus = require "./stylus"

STYLUS_FUNC_FILE = require("path").dirname(require.resolve 'stylus') + '/lib/functions/index.styl'

class Console
  constructor: (@project) ->
    _.bindAll @, "_onFileAdd", "_onFileRemove", "_onFileChange", "disableConsole", "callAPI", "callClient", "onBackup"

    winston.info 'Create console', project: @project.id

    @imports = {}
    @clientId = 0

    Backbone.connector.connect new FoldList null, backend: "folds-#{project.id}"
    Backbone.connector.connect new PseudoList null, backend: "pseudos-#{project.id}"
    Backbone.connector.connect @states = new StateList null, backend: "state-#{@project.id}"
    @states.create {}, wait: true

    @files = new FileList null, backend: "files-#{@project.id}"
    Backbone.connector.connect @files    
    @files.bind "add", @_onFileAdd
    @files.bind "remove", @_onFileRemove
    @files.bind "updated", @_onFileChange
    @_scanDirectoryForFiles()
    
    _.each @project.getClients(), @_onClientAdd, @
    @project.bind "clients:add", @_onClientAdd, @

  _onClientAdd: (client) ->
    winston.debug 'Client added', client: client.id
    @setClientFiles client.id, client.get "css"
    client.bind "change:css", @_onClientChange, @
    client.bind "change:connected", @_onClientChange, @
    client.bind "remove", @_onClientRemove, @

  _onClientChange: (client) ->
    if client.get 'connected'
      @setClientFiles client.id, client.get "css"
    else
      client.published = {} 
      
  _onClientRemove: (client) ->
    @setClientFiles client.id, []

  _scanDirectoryForFiles: ->
    #get the files configuration
    files = @project.get "files"
    _.each files, ({url, path, type, newfiles, stylusout}) =>
      return winston.error 'Access denied to scan files from', path: path unless pathIsAllowed path
      fs.readdir path, (err, flist) =>
        return winston.error 'Failed to scan directory for files', path: path, err: err if err
        flist.forEach (file) =>
          return unless file[0] != '.' && file.match (if type == "stylus" then /\.styl$/i else /\.css$/i)
          #add watcher to all these files
          fpath = path + file
          url += "/" if url[-1..][0] != "/"
          furl = url + file.replace /\.styl$/i, ".css"
          fname = _.last file.split /[\\\/]/
          file = @files.find (f) -> furl == f.get "url"
          if file
            file.save keepalive: true
          else
            fs.stat fpath, (err, stat) =>
              @files.create url: furl, name: fname, fsize: stat.size, mtime: stat.mtime, type: type, keepalive: true, (wait: true)

  listenFile: (file) ->
    watcher.watch file.srcpath, => @files.trigger "updated", file
    @files.trigger "updated", file, true
    winston.debug 'Listen on file', project: @project.id, url: file.get("url"), path: file.srcpath

  _onFileAdd: (file) ->
    @_added ?= {}
    return if @_added[file.id]
    @_added[file.id] = 1 #todo: bug double event
    url = file.get "url"    
    if url.match /^#local/
      file.srcpath = file.get "path"
      @listenFile file
    else getFileLocation @project, url, (err, srcpath, csspath) =>
      unless err 
        file.srcpath = srcpath
        file.csspath = csspath
        @listenFile file
        

  _onFileRemove: (file) ->
    delete @_added[file.id]
    watcher.unwatch file.srcpath
    winston.debug 'Deactivate file', project: @project.id, path: file.srcpath    

  _onFileChange: (f, isInitial) ->
    winston.debug 'Updated file', path: f.srcpath
    @publish f
    fs.stat f.srcpath, (err, stat) =>
      f.save mtime: stat.mtime, fsize: stat.size unless isInitial
    
      for parent, imports of @imports
        if f.srcpath in imports
          file = @files.find (ff) -> ff.srcpath == parent && ff.get('mtime') < f.get('mtime')
          @publish file if file

  destroy: ->
    winston.info 'Destory console', project: @project.id
    @files.each (file) => @_onFileRemove file
    @deactivateSocket @socket if @socket

  pathToUrl: (path) ->
    files = @project.get "files"
    for {url, path: fpath, type, newfiles, stylusout} in files
      if (path.indexOf fpath) == 0
        return url + path.substr(fpath.length)
    null

  publish: (file, clients) ->
    return unless file.csspath
    clients ?= file.get 'clients'
    url = file.get 'url'
    return winston.error 'Could not publish', path: file.srcpath unless file.srcpath
    
    return unless pathIsAllowed file.srcpath
    fs.readFile file.srcpath, "utf8", (err, data) =>
      return winston.error 'Failed to read source file', path: file.srcpath, err: err if err
      data = data.substr 1 if data.charCodeAt(0) == 65279 #todo: better solutions needed
      if file.get('type') == 'stylus'
        winston.info 'Render Stylus file', file: file.srcpath
        stylus.renderStylus file.srcpath, data, (err, css, imports) =>
          return winston.warning 'Failed to render Stylus.', path: file.srcpath, err: err if err
          @stylusSetFileImports file.srcpath, imports
          @publishData file, css, clients
          winston.debug "Writing compiled CSS file:", csspath: file.csspath, clients: clients.length
          fs.writeFile file.csspath, css
          
      else
        @publishData file, data, clients

  publishData: (file, data, clients) ->
    clients ?= file.get 'clients'
    url = file.get 'url'
    data = data.substr 1 if data.charCodeAt(0) == 65279 #todo: better solutions needed
    _.each clients, (clientId) ->
      client = Clients.get(clientId)
      return winston.notice "Client lost without cleanup", client: clientId unless client
      callClient clientId, "setStyles", url: url, data: data
      winston.info "Sending new styles", client: clientId, uid: client.cid, url: url, length: data.length

  publishFile: (file, clients) ->
    clients ?= file.get 'clients'
    return winston.error 'Could not publish file', file: file.csspath unless file.csspath
    fs.readFile file.csspath, "utf8", (err, data) =>
      return winston.error 'Failed to read file', file: file.csspath, err: err if err
      #winston.debug 'Publish file', file: file.csspath
      @publishData file, data, clients

  addClientToFile: (file, clientId) ->
    winston.debug 'addClientTOFile', file: file.get('url'), client: clientId
    clients = _.clone file.get "clients"
    if clientId not in clients
      clients.push clientId
      file.save clients: clients
    client = Clients.get(clientId)
    client.published ?= {}
    url = file.get('url')
    unless client.published[url]
      @publishFile file, [clientId]
      client.published[url] = true

  setClientFiles: (clientId, css) ->
    flist = @files #todo: use bind
    winston.debug 'Set client files', files: css, client: clientId
    _.each css, (cssfile) =>
      file = flist.find (f) -> cssfile == f.get "url"
      if file
        @addClientToFile file, clientId
      else
        getFileLocation @project, cssfile, (err, srcpath) =>
          return if err
          winston.debug 'Client got file location', file: cssfile, err: err, srcpath: srcpath
          
          # TODO: bad pattern.
          file = flist.find (f) -> cssfile == f.get "url"
          if file
            return @addClientToFile file, clientId
          
          # First time seen.
          name = _.last srcpath.split /[\\\/]/
          type = if srcpath.match /\.styl$/i then 'stylus' else 'css'
          fs.stat srcpath, (err, stat) =>
            flist.create url: cssfile, name: name, fsize: stat.size, mtime: stat.mtime, clients: [clientId], type: type, (wait: true)

      # Remove files that were part of this client but not any more.
      flist.each (file) ->
        url = file.get "url"
        clients = file.get "clients"
        keepalive = file.get "keepalive"
        if clientId in clients && url not in css
          clients = _.without clients, clientId
          if !keepalive and clients.length == 0
            file.destroy()
          else
            file.save clients: clients

  activateSocket: (socket) ->
    @socket = socket
    socket.on 'callAPI', @callAPI
    socket.on 'callclient', @callClient
    socket.on 'deactivate', @disableConsole
    socket.on 'disconnect', @disableConsole

  deactivateSocket: (socket) ->
    socket.on 'backup', @onBackup
    socket.emit 'deactivate'
    socket.removeListener 'callAPI', @callAPI
    socket.removeListener 'callclient', @callClient
    socket.removeListener 'deactivate', @disableConsole
    socket.removeListener 'disconnect', @disableConsole    
    @socket = null
    
  onBackup: (data) ->
    @socket?.emit 'startupdata', data
  
  disableConsole: ->
    if @clientId
      callClient @clientId, "deactivate"
      @clientId = 0
    if @socket
      @deactivateSocket @socket

  callAPI: (name, params, cb) -> 
    this["api#{name}"]? params, cb

  callClient: (clientId) ->
    callClient arguments... if @clientId == clientId

  activateConsole: (socket, clientId) ->
    winston.info 'Activate console', client: clientId, old: @clientId
    if socket.id != @socket?.id
      @deactivateSocket @socket if @socket
      @activateSocket socket
    if @clientId and @clientId != clientId
      callClient @clientId, "deactivate"
    if clientId
      callClient clientId, "activate"
    @clientId = clientId
    socket.emit 'activate'

  onClientMessage: (name, params) ->
    @socket?.emit 'clientmessage', name, params

  apiGetImgList: (params, cb) ->
    parts = params.url.split "/"
    base = parts[...-1]
    key = parts[-1..][0]
    files = @project.get "files"
    if files
      for {url, path:fpath, stylusout, type} in files
        fpath = stylusout if type == 'stylus'
        fpath += '/' unless '/' == _.last fpath
        urlparts = url.split "/"
        if urlparts[2] == parts[2]
          fpath = fpath.split "/"
          i = 0
          while true
            break if urlparts[i] != base[i]
            i++
          fpath = fpath[...-urlparts.length+i]
          fpath = fpath.concat base[i..]
          fpath = fpath.join "/"

          fs.stat fpath, (err, stats) ->
            return cb null if err or stats.isFile()

            #console.log "read", fpath, key

            fs.readdir fpath, (err, files) ->
              return cb null if err

              files = _.map files, (file) ->
                return false if (file[0] == ".") or (0 != file.toLowerCase().indexOf key)
                try
                  st = fs.statSync(fpath + "/" + file)
                catch err
                  return false

                if st.isDirectory()
                  file + "/"
                else
                  if file.match /\.(png|jpe?g|gif)$/i
                    file
                  else
                    false
              cb _.compact files.sort()

          return

  apiPublishChanges: (params, cb) ->
    winston.debug 'API called publish changes'
    file = @files.find (f) -> params.url == f.get "url"
    @publishData file, params.data if file
    cb()

  apiGetFileData: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    return unless file?.srcpath
    winston.info "Reading file", path: file.srcpath, url: file.get('url')
    if file
      fs.readFile file.srcpath, "utf8", (err, data) -> 
        return winston.error 'Failed to read file', file: file.srcpath, err: err if err
        cb data: data, name: basename file.srcpath
    else
      cb data: null

  apiSetFileData: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    return unless file?.srcpath and pathIsAllowed file.srcpath
    winston.info 'Writing file', file: file.srcpath, length: params.data.length
    fs.writeFile file.srcpath, params.data, (err) ->
      winston.error 'Failed to write file', file: file.srcpath, err: err if err
      cb err
    
  apiPublishSaved: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    @publishFile file

  stylusSetFileImports: (file, imports) ->
    return delete @imports[file] unless imports
    nibpath = require("nib").path
    @imports[file] = _.compact _.map imports, (item) =>
      return if item.path == STYLUS_FUNC_FILE
      path = item.path
      url = @pathToUrl path
      file = @files.find (f) -> f.srcpath == path
      if not file
        furl = if 0 == path.indexOf nibpath
          path[nibpath.length+1..]
        else
          Math.random() * 1e6 | 0
        name = _.last path.split /[\\\/]/
        fs.stat path, (err, stat) =>
          @files.create fsize: stat.size, mtime: stat.mtime, url: "#local/" + furl, path: path, type: 'stylus', name: name, (wait: true)
      path


  apiGetStylusOutline: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    return unless file
    publish = !!params.publish
    stylus.getStylusOutline filename: file.srcpath, data: params.data, getcss: publish, (outline, css) =>
      #winston.debug 'Requested outline', file: file.get('url'), publish: publish
      cb outline
      @publishData file, css if css


Console.consoles = {}
Console.getConsole = (projectId) ->
  return null unless project = Projects.get projectId
  Console.consoles[projectId] ?= new Console project
  project.bind "remove", ->
    winston.info 'Remove console', project: projectId
    Console.consoles[projectId]?.destroy()
    delete Console.consoles[projectId]
  
  project.bind "change:files", ->
    winston.info 'Console conf changed', project: projectId
    Console.consoles[projectId]?.destroy()
    delete Console.consoles[projectId]
    Console.getConsole(projectId)
    
  Console.consoles[projectId]

module.exports = Console