fs = require "fs"
{_} = require "underscore"

# Shim for watching file changes.
# Handles multiple callbacks registration and group unregister.
# Uses watch() on windows and watchFile() on other platforms.
class FileWatcher
  constructor: ->
    @watchers = {}
    @modifiedTimes = {}
    @isWindows = !!process.platform.match /^win/i

  watch: (path, callback) ->
    return if @watchers[path]
    if @isWindows
      @modifiedTimes[path] = (fs.statSync path).mtime.getTime()
      @watchers[path] = fs.watch path, (event) =>
        modifiedTimes = (fs.statSync path).mtime.getTime()
        if event == "change" && modifiedTimes != @modifiedTimes[path]
          @modifiedTimes[path] = modifiedTimes
          callback()
    else
      fs.watchFile path, interval:100, (curr, prev) ->
        if curr.mtime.getTime() != prev.mtime.getTime()
          callback()
      @watchers[path] = 1
    
  unwatch: (path) ->
    return unless @watchers[path]
    if @isWindows
      @watchers[path].close()
    else
      fs.unwatchFile path
    delete @watchers[path]

exports.FileWatcher = FileWatcher
exports.watcher = new FileWatcher