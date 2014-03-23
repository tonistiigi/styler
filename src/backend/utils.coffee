path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
os = require 'os'
request = require 'request'
{_} = require 'underscore'
log = require './log'

# Try to return style file path based on a url using project configuration. 
exports.getFileLocation = (project, fileurl, cb) ->
  files = project.get 'files'
  if files
    for {url, path:fpath, type, newfiles, stylusout} in files
      if 0 == fileurl.indexOf url
        srcfile = cssfile = (fpath + '/' + fileurl.substr url.length).replace /\/+/g, '/'
        if type == 'stylus'
          srcfile = srcfile.replace /\.css$/i, '.styl'
          cssfile = (stylusout + '/' + fileurl.substr url.length).replace /\/+/g, '/'
          newfiles = false
        return fs.exists srcfile, (found) ->
          if found
            cb null, srcfile, cssfile
          else if newfiles && fileurl.match /^http/
            log.info project: project.id, file: srcfile, 'File was not found. Trying to create new.'
            # Create empty file and fill it with HTTP request result.
            request fileurl, (error, response, body) ->
              if error || response.statusCode != 200
                log.warn file: srcfile, url: fileurl, err: error, statusCode: response?.statusCode, 'Failed to get contents for the file.'
                body = "" 
              else
                log.info file: srcfile, url: fileurl, statusCode: response.statusCode, length: body.length, 'Received contents for file.'
              srcdir = path.dirname srcfile
              writefile = ->
                fs.writeFile srcfile, body, 'utf8', (err) ->
                  if err
                    log.error file: srcfile, err: err, 'Failed to write new file'
                    cb true
                  else
                    log.info file: srcfile, 'Created new file'
                    cb null, srcfile, cssfile
              fs.exists srcdir, (found) ->
                if found
                  writefile()
                else
                  log.info path: dir, 'Creating directory'
                  mkdirp dir, 0o755, -> writefile()
              
          else
            log.warn file: srcfile, 'File was not found. Ignoring.'
            cb true # File should be ignored.
  log.debug project: project.id, url: fileurl, 'File didn\'t match project configuration'
  cb true # No file configuration.

###
exports.getStylusAssumption = (project, fileurl) ->
  files = project.get "files"
  if files 
    for {url, daemon} in files
      return !!daemon if (fileurl.indexOf url) == 0
  false

exports.setStylusAssumption = (project, fileurl, value) ->
  files = project.get "files"
  if files 
    for {url},i in files
      files[i].daemon = !!value if (fileurl.indexOf url) == 0
  project.save files:files
###


# Get local network IPs. Used to detect(and allow) local connections.
exports.getLocalIPs = do ->
  cached = null
  (callback, bypassCache) ->
    return callback cached if cached && !bypassCache
    ips = []
    if process.platform.match /^win/i
      # Based on <http://stackoverflow.com/questions/3653065>
      {exec} = require 'child_process'
      command = 'ipconfig'
      filterRE = /\IPv4 Address(.+?)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/gim
      exec command, (error, stdout, sterr) ->
        unless error
          # extract IPs
          matches = stdout.match filterRE
          if matches
            # JS has no lookbehind REs, so we need a trick
            ips = (match.match(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)[0] for match in matches)
            # filter BS
        ips.unshift '127.0.0.1'
        callback cached = ips
    else
      for name, interfaces of os.networkInterfaces()
        for intrface in interfaces
          if intrface.family == 'IPv4'
            ips.push intrface.address
      callback cached = ips


exports.isAllowedIP = (allowed, ip) ->
  for check in allowed
    check = check.trim()
    continue unless check.length
    regexp = new RegExp "^" + (check.replace /\./g, "\\.").replace /\*/, ".+"
    return true if ip.match regexp
  false

# TODO: Is there a native way for doing this??
exports.getDriveNames = (cb) ->
  cb null unless !!process.platform.match /^win/i
  {exec} = require 'child_process'
  command = 'wmic logicaldisk get name'
  exec command, (error, stdout, sterr) ->
    if error
      log.warn err: error, output: stdout, 'Failed to get drive names using wmic'
      return callback error 
    # extract IPs
    matches = stdout.match /[a-z]\:/ig
    return cb matches if matches
    # Fallback(just in case).
    [match] = __dirname.match /^[a-z]\:/i
    return cb ([match] || null)


# Check if part is inside the root directory defined in command line.
exports.pathIsAllowed = (fpath) ->
  return true if global.rootDir == '/'
  0 == path.normalize(fpath).replace( /\\/g, "/").toLowerCase().indexOf global.rootDir.toLowerCase()


# Return user's home directory.
exports.getHomeDir = ->
  process.env.HOME || process.env.HOMEPATH.replace(/\\/g, '/') || '.'