define (require, exports, module) ->

  {addCommandKeyListener} = require 'ace/lib/event'
  ua = require 'ace/lib/useragent'
  {CommandManager} = require 'ace/commands/command_manager'

  tabIndex = 0
  commands = {}
  initialized = false

  createManager = ->
    new CommandManager if ua.isMac then 'mac' else 'win'

  managers =
    global: createManager()

  # Reset keyboard commands after they are changed in settings.
  onKeySettingsChange = ->
    keyCommands = app.Settings.get 'keyboard_shortcuts'
    for name, keys of keyCommands
      command = commands[name]
      continue unless command
      managers[command.scope].removeCommand name
      command.bindKey.mac = keys.mac
      command.bindKey.win = keys.win || keys.mac
      managers[command.scope].addCommand command

  dispatch = (scope, e, hashId, keyOrText) ->
    cmd = managers[scope].findKeyCommand hashId, keyOrText
    if !cmd && scope != 'global'
      cmd = managers.global.findKeyCommand hashId, keyOrText
    return unless cmd
    managers[scope].exec cmd
    e.stopPropagation()
    e.preventDefault()

  exports.addKeyboardListener = (scope, element, forcedTabIndex=null) ->
    setManager = element instanceof CommandManager

    if setManager
      managers[scope] = element
    else
      if forcedTabIndex == null then tabIndex++ else tabIndex = forcedTabIndex
      element.setAttribute? 'tabIndex', tabIndex
      element.listenKey = _.bind exports.listenKey, @, scope
      addCommandKeyListener element, _.bind dispatch, @, scope
      managers[scope] = createManager()

  exports.listenKey = (scope, name, opt) ->
    scope ||= 'global'
    unless initialized
      app.Settings.bind 'change:keyboard_shortcuts', onKeySettingsChange
      initialized = true

    keyCommands = app.Settings.get 'keyboard_shortcuts'
    if keyCommands[name]
      opt.mac = keyCommands[name].mac
      opt.win = keyCommands[name].win || opt.mac
    managers[scope].addCommand command =
        name: name
        bindKey:
          win: opt.win || opt.mac
          mac: opt.mac
          sender: scope
        exec: opt.exec
        scope: scope
    commands[name] = command if keyCommands[name]

  exports.formatKeyCommand = (commandStr) ->
    if ua.isMac
      parts = _.map (commandStr.split '-'), (part) ->
        part = part.toLowerCase()
        switch part
          when 'command' then '⌘'
          when 'alt' then '⌥'
          when 'ctrl' then '⌃'
          when 'shift' then '⇧'
          when 'tab' then '⇥'
          when 'return' then '⏎'
          when 'backspace' then '⌫'
          when 'right' then '→'
          when 'left' then '←'
          when 'up' then '↑'
          when 'down' then '↓'
          else
            (_.map (part.split ' '), (p) -> p.charAt(0).toUpperCase() + p.slice 1).join ' '
      parts.join ''
    else
      commandStr

  exports
