define (require, exports, module) ->
  {_, Backbone} = if window? then window else {_: require(['underscore'][0]), Backbone: require ['backbone'][0]}
  
  Project = Backbone.Model.extend
    defaults: ->
      lastTime: +new Date()
      filePaths: []
      tabSize: 2
      softTabs: true
      mode: 0

    setActive: (value) ->
      @isActive = value
      @trigger 'change'
      
    getClients: ->
      @collection.clients.select (client) => @id == client.get('project')

  ProjectList = Backbone.Collection.extend
    model: Project
    backend: 'projects'

    initialize: (models, opt) ->
      @clients = opt.clients
      @clients.on 'add', @onClientAdd, @
      @clients.on 'change:project', @onClientProjectChange, @
      @clients.on 'remove', @onClientRemove, @
      
      @activeProject = null

    onClientAdd: (client) ->
      if projectId = client.get('project')
        @get(projectId)?.trigger 'clients:add', client
      
    onClientProjectChange: (client) ->
      if projectId = client._previousAttributes['project']
        @get(projectId)?.trigger 'clients:remove', client
      if projectId = client.get('project')
        @get(projectId)?.trigger 'clients:add', client
    
    onClientRemove: (client) ->
      if projectId = client.get('project')
        @get(projectId)?.trigger 'clients:remove', client

    comparator: (p) ->
      -p.get 'lastTime'

    setActive: (id) ->
      model = @get id
      return if !model or model == @activeModel
      @activeModel.setActive false if @activeModel
      @activeModel = model
      model.setActive true if model

  Client = Backbone.Model.extend
    defaults: ->
      project: 0
      session_id: ~~(Math.random() * 1e8)
      connected: true
      agenttype: 'unknown'

    validate: (attrs) ->
      return true unless @get('session_id')
      false

  ClientList = Backbone.Collection.extend
    backend: 'clients'
    model: Client
    
    comparator: (client) ->
      -client.get 'lastTime'

  File = Backbone.Model.extend
    defaults: ->
      position: [0, 0]
      clients: []
      name: ''
      type: 'css'

    validate: (attrs) ->
      return false if @id
      url = attrs?.url || @get('url')
      !!@collection.find (file) -> url == file.get 'url'

  FileList = Backbone.Collection.extend
    model: File

    comparator: (file) ->
      file.get('url').toLowerCase()

  Fold = Backbone.Model.extend {}
  FoldList = Backbone.Collection.extend
    model: Fold
  
  Pseudo = Backbone.Model.extend {}
  PseudoList = Backbone.Collection.extend
    model: Pseudo

  State = Backbone.Model.extend
    defaults: ->
      selectedItem : null
      selectedUrl : ''
      infobarVisible : true
      leftPaneVisible : true
      outlineLock : false
      dirCollapsed: {}

  StateList = Backbone.Collection.extend
    model: State

  Settings = Backbone.Model.extend
    defaults: ->
      theme: 'textmate'
      save_icon: true
      line_numbers: true
      invisibles: false
      statusbar: true
      sidebar_right : false
      csslint:
        'box-model':1, 'display-property-grouping':1, 'duplicate-properties':1
        'empty-rules':1, 'known-properties':1, 'adjoining-classes':0, 'box-sizing':0
        'compatible-vendor-prefixes':1, 'gradients':1, 'text-indent':1, 'vendor-prefix':1
        'font-faces':1, 'import':1, 'regex-selectors':1, 'universal-selector':1
        'zero-units':0, 'overqualified-elements':1, 'shorthand':1, 'floats':1
        'font-sizes':1, 'ids':0, 'important':1, 'outline-none':1
        'qualified-headings':1, 'unique-headings':1
      keyboard_shortcuts:
        'focus-tree': (mac: 'F2')
        'focus-styleinfo': (mac: 'F1')
        'focus-clientswitch': (mac: 'F3')
        'focus-editor': (mac: 'F4')
        'toggle-window-mode': (mac: 'shift-command-e', win: 'ctrl-shift-e', export:
          mac: (code: 69, meta: true, shift: true, txt: '⇧⌘E')
          win: (code: 69, ctrl: true, shift: true, txt: 'Ctrl-Shift-E')
        )
        'start-inspector-mode': (mac: 'shift-command-p', win: 'ctrl-shift-p', export:
          mac: (code: 80, meta: true, shift: true, txt: '⇧⌘P')
          win: (code: 80, ctrl: true, shift: true, txt: 'Ctrl-Shift-P')
        )
        'toggle-iframe-container': (mac: 'command-k', win: 'ctrl-k', export:
          mac: (code: 75, meta: true, txt: '⌘K')
          win: (code: 75, ctrl: true, txt: 'Ctrl-K')
        )
        'back-to-project-list': (mac: 'shift-command-esc', win: 'ctrl-alt-esc', linux: 'ctrl-shift-esc')
        'toggle-cli': (mac: 'esc')
        'settings': (mac: 'command-,', win: 'ctrl-,')
        'toggle-update-mode': (mac: 'command-alt-e', win: 'ctrl-alt-e')
        'toggle-tab-mode': (mac: 'alt-t', win: 'alt-t')

        'select-focused-selector': (mac: 'command-i', win: 'ctrl-i')
        'select-focused-selector-reverse': (mac: 'shift-command-i', win: 'ctrl-shift-i')
        'toggle-infobar': (mac: 'shift-command-O', win: 'ctrl-shift-O')
        'toggle-left-pane': (mac: 'alt-command-O', win: 'ctrl-alt-O')

        'select-previous-element': (mac: 'up', scope: 1)
        'select-next-element': (mac: 'down', scope: 1)
        'select-down-many': (mac: 'alt-down', scope: 1)
        'select-up-many': (mac: 'alt-up', scope: 1)
        'fold-element': (mac: 'right', scope: 1)
        'unfold-element': (mac: 'left', scope: 1)

        'select-outline-subtree': (mac: 'command-return', win: 'ctrl-return')
        'hide-outline-subtree': (mac: 'command-backspace', win: 'ctrl-backspace')
        'scroll-to-view': (mac: 'shift-command-space', win: 'ctrl-shift-space')
        'focus-element-styleinfo': (mac: 'return')
        'switch-back-to-outline': (mac: 'backspace')

        'style-item-down': (mac: 'down', scope: 2)
        'style-item-up': (mac: 'up', scope: 2)
        'style-item-expand': (mac: 'right', scope: 2)
        'style-item-collapse': (mac: 'left', scope: 2)
        'style-item-open': (mac: 'return', scope: 2)
        'style-selector-up': (mac: 'alt-up', scope: 2)
        'style-selector-down': (mac: 'alt-down', scope: 2)

        'select-filebrowser': (mac: 'command-0', win: 'ctrl-0')
        'save-tab': (mac: 'command-s', win: 'ctrl-s')
        'save-all': (mac: 'shift-command-s', win: 'ctrl-shift-s')
        'close-tab': (mac: 'ctrl-w', win: 'alt-w')
        'focus-selector-up': (mac: 'shift-alt-up')
        'focus-selector-down': (mac: 'shift-alt-down')
        'search-in-file': (mac: 'command-f', win: 'ctrl-f')
        'search-next-result': (mac: 'command-g', win: 'ctrl-k', scope: 3)
        'search-previous-result': (mac: 'command-shift-g', win: 'ctrl-shift-k', scope: 3)
        'indent-selection': (mac: 'alt-tab', win: 'ctrl-alt-shift-right')
        'outdent-selection': (mac: 'shift-alt-tab', win:'ctrl-alt-shift-left')
        'numeric-increment': (mac: 'ctrl-alt-up')
        'numeric-decrement': (mac: 'ctrl-alt-down')
        'numeric-increment-many': (mac: 'ctrl-alt-right')
        'numeric-decrement-many': (mac: 'ctrl-alt-left')
        'edit-value': (mac: 'command-e', win: 'ctrl-e')
        'new-property': (mac: 'alt-command-n', win: 'ctrl-alt-n')
        'show-completions': (mac: 'ctrl-space')

      confirm_keyboard_close: true
      confirm_unsaved_close: true
      autocomplete: true
      fpsstats: false
      devmode: true
      activeonly: false

  SettingsList = Backbone.Collection.extend
    model: Settings
    backend: 'settings'

  _.extend exports,
    Project: Project
    ProjectList: ProjectList
    Client: Client
    ClientList: ClientList
    File: File
    FileList: FileList
    State: State
    StateList: StateList
    Fold: Fold
    FoldList: FoldList
    Pseudo: Pseudo
    PseudoList: PseudoList
    Settings: Settings
    SettingsList: SettingsList
