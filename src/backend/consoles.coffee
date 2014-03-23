fs = require "fs"
{_} = require "underscore"
Backbone = require "backbone"
Console = require "./console"
{Clients} = require "./data"
{pathIsAllowed, getDriveNames, isAllowedIP} = require "./utils"
log = require './log'
io = global.io

io.of("/console").on 'connection', (socket) ->
  return socket.disconnect() unless isAllowedIP global.allowed, socket.handshake.address.address
  socket.on 'checkDir', checkDir
  socket.on 'browseFiles', browseFiles
  socket.on 'getRoot', getRoot
  Backbone.connector.addClient socket
  socket.on 'activate', (projectId, clientId) ->
    (Console.getConsole projectId)?.activateConsole socket, clientId

checkDir =  (clientId, url, path, stylusoutPath, cb) ->  
  client = Clients.get clientId
  return unless client
  
  return cb(status: "no-directory") unless path.length && pathIsAllowed path
  fs.stat path, (err, stat) ->
    return cb(status: "no-directory") if err or !stat.isDirectory()
    
    css = client.get "css"
    filenames = (file.substr url.length for file in css when 0 == file.indexOf url)

    files = {}
    type = "unknown"
    stylusout = false
    stylusoutExists = fs.existsSync stylusoutPath
    for filename in filenames
      fullPath = path + filename
      fullPathStylus = fullPath.replace /\.css$/i, ".styl"
      existsStylus = fs.existsSync fullPathStylus
      if existsStylus
        type = "stylus"
        files[filename] = true
        stylusout = true if stylusoutExists && fs.existsSync stylusoutPath + filename
      else 
        existsCSS = fs.existsSync fullPath
        if existsCSS
          type = "css"
          files[filename] = true
        else
          files[filename] = false
    cb status: "ok", type: type, files: files, stylusout: stylusout, stylusoutExists: stylusoutExists

browseFiles = (path, cb) ->
  path = path.replace /^\//, global.rootDir if global.rootDir != '/'
  res = dirs: [], files: []
  return log.warning path: path, 'Browsing files not allowed for path.' unless pathIsAllowed path
  fs.stat path, (err, stat) ->
    if err or !stat.isDirectory()
      lgo.warn path: path, err: err, 'Could not browse files inside directory.'
      return cb res 
    fs.readdir path, (err, files) ->
      if files
        for file in files
          continue if file[0] == '.' #no hidden needed
          try
            st = fs.statSync(path + "/" + file)
          catch err
            continue
          res.dirs.push file if st.isDirectory()
          res.files.push file if st.isFile() and file.match /\.(css|styl|scss)$/i
      if path != '/' || !process.platform.match /^win/i
        cb res
      else
        getDriveNames (names) ->
          res.drives = names
          cb res

getRoot = (cb) ->
  cb global.rootDir
