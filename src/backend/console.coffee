fs = require "fs"
{basename} = require "path"
Backbone = require "backbone"
requirejs = require "requirejs"
{_} = require "underscore"
{callClient} = require "./clients"
{Clients, Projects} = require "./data"
{getFileLocation, relativeURL, pathIsAllowed} = require "./utils"
{FileList, File, StateList, FoldList, PseudoList} = requirejs "./../public/lib/models"
{watcher} = require "./filewatcher"
stylus = require "./stylus"
log = require './log'

STYLUS_FUNC_FILE = require("path").dirname(require.resolve 'stylus') + '/lib/functions/index.styl'

class Console
  constructor: (@project) ->
    _.bindAll @, "_onFileAdd", "_onFileRemove", "_onFileChange", "disableConsole", "callAPI", "callClient", "onBackup"

    log.info project: @project.id, 'Create console'

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
    log.debug client: client.id, 'Client added'
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
      return log.error path: path, 'Access denied to scan files' unless pathIsAllowed path
      fs.readdir path, (err, flist) =>
        return log.error  path: path, err: err, 'Failed to scan directory for files' if err
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
    log.debug project: @project.id, url: file.get("url"), path: file.srcpath, 'Listen on file'

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
    log.debug project: @project.id, path: file.srcpath, 'Deactivate file'

  _onFileChange: (f, isInitial) ->
    log.debug path: f.srcpath, 'Updated file'
    @publish f
    fs.stat f.srcpath, (err, stat) =>
      f.save mtime: stat.mtime, fsize: stat.size unless isInitial
    
      for parent, imports of @imports
        if f.srcpath in imports
          file = @files.find (ff) -> ff.srcpath == parent && ff.get('mtime') < f.get('mtime')
          @publish file if file

  destroy: ->
    log.info project: @project.id, 'Destory console'
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
    return log.error path: file.srcpath, 'Could not publish' unless file.srcpath
    
    return unless pathIsAllowed file.srcpath
    fs.readFile file.srcpath, "utf8", (err, data) =>
      return log.error path: file.srcpath, err: err, 'Failed to read source file' if err
      data = data.substr 1 if data.charCodeAt(0) == 65279 #todo: better solutions needed
      if file.get('type') == 'stylus'
        log.info file: file.srcpath, 'Render Stylus file'
        stylus.renderStylus file.srcpath, data, (err, css, imports) =>
          return log.warn path: file.srcpath, err: err, 'Failed to render Stylus.' if err
          @stylusSetFileImports file.srcpath, imports
          @publishData file, css, clients
          log.debug csspath: file.csspath, clients: clients.length, 'Writing compiled CSS file:'
          fs.writeFile file.csspath, css
          
      else
        @publishData file, data, clients

  publishData: (file, data, clients) ->
    clients ?= file.get 'clients'
    url = file.get 'url'
    data = data.substr 1 if data.charCodeAt(0) == 65279 #todo: better solutions needed
    _.each clients, (clientId) ->
      client = Clients.get(clientId)
      return log.warn client: clientId, "Client lost without cleanup" unless client
      callClient clientId, "setStyles", url: url, data: data
      log.info client: clientId, uid: client.cid, url: url, length: data.length, "Sending new styles"

  publishFile: (file, clients) ->
    clients ?= file.get 'clients'
    return log.error file: file.csspath, 'Could not publish file' unless file.csspath
    fs.readFile file.csspath, "utf8", (err, data) =>
      return log.error file: file.csspath, err: err, 'Failed to read file' if err
      @publishData file, data, clients

  addClientToFile: (file, clientId) ->
    log.debug file: file.get('url'), client: clientId, 'addClientToFile'
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
    log.debug files: css, client: clientId, 'Set client files'
    _.each css, (cssfile) =>
      file = flist.find (f) -> cssfile == f.get "url"
      if file
        @addClientToFile file, clientId
      else
        getFileLocation @project, cssfile, (err, srcpath) =>
          return if err
          log.debug file: cssfile, err: err, srcpath: srcpath, 'Client got file location'
          
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
    log.info client: clientId, old: @clientId, 'Activate console'
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
    log.debug 'API called publish changes'
    file = @files.find (f) -> params.url == f.get "url"
    @publishData file, params.data if file
    cb()

  apiGetFileData: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    return unless file?.srcpath
    log.info path: file.srcpath, url: file.get('url'), "Reading file"
    if file
      fs.readFile file.srcpath, "utf8", (err, data) -> 
        return log.error file: file.srcpath, err: err, 'Failed to read file'  if err
        cb data: data, name: basename file.srcpath
    else
      cb data: null

  apiSetFileData: (params, cb) ->
    file = @files.find (f) -> params.url == f.get "url"
    return unless file?.srcpath and pathIsAllowed file.srcpath
    log.info file: file.srcpath, length: params.data.length, 'Writing file'
    fs.writeFile file.srcpath, params.data, (err) ->
      log.error file: file.srcpath, err: err, 'Failed to write file' if err
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
      cb outline
      @publishData file, css if css


Console.consoles = {}
Console.getConsole = (projectId) ->
  return null unless project = Projects.get projectId
  Console.consoles[projectId] ?= new Console project
  project.bind "remove", ->
    log.info project: projectId, 'Remove console'
    Console.consoles[projectId]?.destroy()
    delete Console.consoles[projectId]
  
  project.bind "change:files", ->
    log.info project: projectId, 'Console conf changed'
    Console.consoles[projectId]?.destroy()
    delete Console.consoles[projectId]
    Console.getConsole(projectId)
    
  Console.consoles[projectId]

module.exports = Console