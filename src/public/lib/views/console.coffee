define (require, exports, module) ->

  TreeOutline = require 'lib/views/ui/treeoutline'
  StyleInfo = require 'lib/views/ui/styleinfo'
  OutlineInfo = require 'lib/views/outlineinfo'
  OutputSwitch = require 'lib/views/outputswitch'
  Resizer = require 'lib/views/ui/resizer'
  {StateList, FoldList, PseudoList} = require 'lib/models'
  {node, highlightSelector, swapNodes, parallel} = require 'lib/utils'
  {addMouseWheelListener, stopEvent} = require 'ace/lib/event'
  {addKeyboardListener, listenKey} = require 'lib/keyboard'
  ua = require 'ace/lib/useragent'

  ConsoleView = Backbone.View.extend
    className: 'app'

    template: require 'lib/templates/console'

    events:
      'click .tool-back': 'showProjectList'
      'click .tool-settings': 'showSettings'
      'click .tool-refresh': 'reloadOutline'
      'click .tool-identify': 'identifyClient'
      'click .tool-inspect': 'startInspector'
      'click .tool-edit': 'editProject'
      'click .tool-embed': 'toggleApplicationMode'
      'click .tool-sidebyside': 'toggleIframeMode'

    initialize: (opt) ->
      _.bindAll @, 'onResize', 'toggleApplicationMode', 'onBeforeUnload', 'onConsoleDeactivated', 'onConsoleActivated', 'onClientMessage', 'toggleInfobar', 'onStartupData', 'toggleUpdateMode', 'toggleTabSettings', 'toggleSidebar', 'onInspectorResult', 'onElementSelected', 'onEmbedMessage'

      app.console = @
      @usesPostMessage = false

      app.socket.on 'activate', @onConsoleActivated
      app.socket.on 'deactivate', @onConsoleDeactivated
      app.socket.on 'clientmessage', @onClientMessage
      app.socket.on 'startupdata', @onStartupData

      @project = opt.project
      @project.on 'clients:add', (client) =>
        @loadClient client if @project.getClients().length == 1 && !@client
      
      # Embed detection.
      if self != top
        window.addEventListener 'message', @onEmbedMessage , false
        top.postMessage 'getEmbedMode', '*'
      
      # Keyboard commands.
      addKeyboardListener 'global', window      
      listenKey null, 'toggle-window-mode', exec: @toggleApplicationMode
      listenKey null, 'toggle-iframe-container', exec: => @callClient 'toggleIframe', {}
      listenKey null, 'focus-tree', exec: => @outline.el.focus()
      listenKey null, 'focus-styleinfo', exec: => @styleInfo.el.focus()
      listenKey null, 'focus-editor', exec: => @editor.focus()
      listenKey null, 'focus-clientswitch', exec: => @clientPicker.el.focus()
      listenKey null, 'settings', exec: => @showSettings()
      listenKey null, 'select-focused-selector', exec: => @selectFocusedSelectorElement()
      listenKey null, 'select-focused-selector-reverse', exec: => @selectFocusedSelectorElement true
      listenKey null, 'back-to-project-list', exec: => @showProjectList()
      listenKey null, 'toggle-infobar', exec: @toggleInfobar
      listenKey null, 'toggle-update-mode', exec: @toggleUpdateMode
      listenKey null, 'toggle-tab-mode', exec: @toggleTabSettings
      listenKey null, 'toggle-left-pane', exec: @toggleSidebar
      
      # Make DOM elements and subviews.
      @$el.html(@template).addClass 'no-client-loaded'

      @clientPicker = new OutputSwitch model: @project, el: @$('.client-select-sidebar')[0]
      @clientPicker.on 'change', @onClientChange, @

      @clientPicker2 = new OutputSwitch model: @project, el: @$('.client-select-toolbar')[0]
      @clientPicker2.on 'change', @onClientChange, @

      @outline = new TreeOutline el: @$('.elements-outline')[0]
      @outline.on 'load', @onOutlineLoaded, @
      @outline.on 'select', _.throttle (_.bind @onElementSelected), 300
      @outline.on 'fold', @onFold, @
      @outline.on 'unfold', @onUnfold, @
      @outline.on 'focus:styleinfo', =>
        @styleInfo.el.focus()
        @styleInfo.moveHighlight 1 unless @styleInfo.highlightElement?

      @styleInfo = new StyleInfo el: @$('.styleinfo')[0]
      @styleInfo.on 'open', @openFile, @
      @styleInfo.on 'focus:outline', => @outline.el.focus()
      
      @outlineInfo = new OutlineInfo el: @$('.infobar-outline')[0]
      @on 'change:pseudo', (pseudo) =>
        @setElementPseudo pseudo.elementId, pseudo.get('pseudos')

      (new Resizer el: @$('.resizer-vertical')[0], name: 'vresizer', target: @$('.styleinfo')[0])
        .on 'resize', @onResize
      (new Resizer el: @$('.resizer-horizontal')[0], name: 'hresizer', target: @$('.sidebar')[0])
        .on 'resize', @onResize

      swapNodes @$('.sidebar')[0], @$('.main-content')[0] if app.Settings.get 'sidebar_right'
      @$('.sidebar-toggle').on 'click', @toggleSidebar
      
      baseUrl = @project.get 'baseurl'
      @$('.no-clients-fallback .url').text(baseUrl)
        .on 'click', -> window.open baseUrl

      @loadClient opt.client

      # Disable elastic scrolling + back swiping.
      $(document.body).addClass 'no-scrolling'
      addMouseWheelListener document, (e) -> stopEvent e if e.wheelX != 0
      
      # Page unload control.
      $(window).on 'beforeunload', @onBeforeUnload


      if !ua.isGecko
        @captureCommandStart = _.bind @captureCommandKey, @, false
        @captureCommandEnd = _.bind @captureCommandKey, @, true
        window.addEventListener 'keydown', @captureCommandStart, true
        window.addEventListener 'keyup', @captureCommandEnd, true

      Backbone.history.onbeforeunload = =>
        block = @checkUnsavedFiles =>
          Backbone.history.onbeforeunload = null
          window.history.back() if block

      # Add ID to the title so extensions can use it for focus switching.
      oldTitle = document.title.replace /\s?\(\d+\)$/, ''
      document.title = oldTitle + " (#{@project.id})"
      tm('console')
      # Load defer components.
      _.delay ->
        require ['lib/editor/statsmanager'], (stats) -> app.stats = stats
      , 1000

      if app.Settings.get 'fpsstats'
        require ['vendor/stats'], =>
          stats = new Stats()
          statsElement = stats.getDomElement()
          $(statsElement).addClass 'fpsstats'
          @$el.append statsElement
          setInterval ->
            stats.update()
          , 1000 / 60
      
      _.delay =>
        require ['lib/views/commandline'], (CommandLine) =>
          new CommandLine el: @$('.cli-container')[0]
      , 1000

      
    activateConsole: ->
      tm('activateConsole')
      app.socket.emit 'activate', @project.id, @client?.id
      
      if @state
        @initState()
      else
        states = new StateList null, backend: 'state-' + @project.id
        if __data.states
          states.reset __data.states
          @state = states.at 0
          console.log @state
          @initState()
          __data.states = null
        else 
          states.fetch success: =>
            @state = states.at(0)
            @initState()
      
      
    initState: ->
      tm('initstate')
      sp =  @state.get 'scrollPos'
      @outline.scrollPosition = sp if sp # TODO: just plain wrong to do it this way.

      # TODO: these need localStorage fallbacks to avoid flicker.

      @state.on 'change:infobarVisible', @renderInforbarVisibility, @
      @renderInforbarVisibility()

      @state.on 'change:outlineLock', @renderFocusLocking, @
      @renderFocusLocking()

      @state.on 'change:leftPaneVisible', @renderSidebarVisibility, @
      @renderSidebarVisibility()
      _.defer =>
        require ['lib/views/editor'], (EditorView) =>
          tm('editorload')
          unless @editor
            @editor = new EditorView el: @$('.editor-container')[0]
            @editor.on 'change:focusedselector', @onFocusedSelectorChange, @
            
          @$('.infobar-toggle').on 'click', @toggleInfobar
          @$('.locking-toggle').on 'click', =>
            @state.save outlineLock: !@state.get 'outlineLock'
        
          @usesPostMessage = false
          @callClientPostMessage 'getSessionId', {}, (resp) =>
            if parseInt(resp.sessionId, 10) == @client.get 'session_id'
              @usesPostMessage = true
          _.delay =>
            @reloadOutline()
            if @getMedia() != 'screen'
              @callClient 'setMedia', {value: @getMedia()}, ->
            @trigger 'change:media'
          , 50

    onConsoleActivated: ->
      tm('activated')
      @active = true

    onConsoleDeactivated: ->
      @backupData()
      @active = false
      require ['lib/views/warning-screen'], (WarningScreen) =>
        top.postMessage 'close-iframe', '*' if @embed
        new WarningScreen name: 'warning_overload'
      @destroy()

    destroy: ->
      @unloadClient()
      app.socket.emit 'deactivate' if @active

      app.socket.removeListener 'activate', @onConsoleActivated
      app.socket.removeListener 'deactivate', @onConsoleDeactivated
      app.socket.removeListener 'clientmessage', @onClientMessage
      app.socket.removeListener 'startupdata', @onStartupData

      $(document.body).removeClass 'no-scrolling'
      $(window).off 'beforeunload', @onBeforeUnload
      window.removeEventListener 'keydown', @captureCommandStart, true
      window.removeEventListener 'keyup', @captureCommandEnd, true
      document.title = '' + document.title.replace /\s*?\(\d+\)$/, ''
      @editor?.destroy()

      app.console = null


    toggleSidebar: ->
      @state.save leftPaneVisible: !@state.get 'leftPaneVisible'
      _.delay =>
        @editor.onResize()
      , 1000
    
    toggleInfobar: ->
      @state.save infobarVisible: !@state.get 'infobarVisible'
      
    toggleUpdateMode: ->
      @project.save mode: (if @project.get('mode') then 0 else 1)

    toggleTabSettings: ->
      tabSize = @project.get 'tabSize'
      softTabs = @project.get 'softTabs'
      switch tabSize
        when 2 then tabSize = 3
        when 3 then tabSize = 4
        when 4 then tabSize = 8
        when 8
          tabSize = 2
          softTabs = !softTabs
      @project.save tabSize: tabSize, softTabs: softTabs
      
    toggleApplicationMode: ->
      @callClient 'toggleApplicationMode', null, -> window.close()

    toggleIframeMode: ->
      top.postMessage 'toggleIframeMode', '*' if @embed

    onEmbedMessage: (e) ->
      if e.data.embedInfo
        if e.data.iframeMode
          @embedSideBySide = e.data.iframeMode == 'sidebyside'
        if e.data.baseURL
          @embed = e.data.baseURL == @project.get('baseurl')
        @renderEmbedMode()

    renderEmbedMode: ->
      if @embed
        @$('.tool-embed').addClass 'is-selected'
        @$('.tool-sidebyside').show().toggleClass 'is-selected', !!@embedSideBySide
      else
        @$('.tool-embed').toggle @client && @client.get('embed')
        @$('.tool-sidebyside').hide()

    renderInforbarVisibility: ->
      @$el.toggleClass 'has-infobar', @state.get 'infobarVisible'

    renderFocusLocking: ->
      @$('.locking-toggle').toggleClass 'is-locked', @state.get 'outlineLock'

    renderSidebarVisibility: ->
      leftPaneVisible = @state.get 'leftPaneVisible'
      @$el
        .toggleClass('no-sidebar', !leftPaneVisible)
        .toggleClass('has-sidebar', leftPaneVisible)

    showProjectList: ->
      @checkUnsavedFiles =>
        if @client?.get('project')
          app.router.navigate 'project/' + @client.get('project'), trigger: true
        else
          app.router.navigate '', trigger: true

    editProject: ->
      @checkUnsavedFiles =>
        app.router.navigate 'edit/' + @project.id, trigger: true

    startInspector: ->
      @callClient 'startInspector', {}, @onInspectorResult
      window.opener?.focus() if @usesPostMessage
      app.socket.emit 'callClient', @client.id, 'focus'

    onInspectorResult: (data) ->
      @_dontInspectOutline = true
      @_wasSelectFromInspect = true
      @outline.select data.id
      app.socket.emit 'callClient', @client.id, 'focus', title: @project.id
      
    showSettings: ->
      app.app.showSettings()
    
    identifyClient: ->
      @callClient 'identify', msg: @client.get('useragent'), ->
      app.socket.emit 'callclient', @client.id, 'focus'

    reloadOutline: ->
      tm('reload')
      @callClient 'getDOMTree', {}, (data) =>
        @_wasSilentRefresh = false
        @outline.setTreeData data.tree
        tm('treedata')

    captureCommandKey: (release, e) ->
      if e.keyCode == (if ua.isMac then 91 else 17)
        @iscommandkey = !release
      else if e.keyCode == 87
        @iswkey = !release
      else if e.keyCode == 16
        @isshiftkey = !release

    onBeforeUnload: (e) ->
      confirm_keyboard_close = app.Settings.get 'confirm_keyboard_close'
      if @iscommandkey && confirm_keyboard_close && @editor.tabs.size() && !@isshiftkey
        @iscommandkey = false
        return [ 'Possibly incorrect action was detected! Closing editor tabs with'
          if ua.isMac then ' ⌘W' else 'Ctrl-W'
          'is not supported by your browser. Use alternative keyboard command'
          if ua.isMac then '⌃W' else 'Alt-W'
          'instead. If you like the default behaviour of your browser you can turn off this message from the settings or include Shift key in your command.'].join ' '

      confirm_unsaved_close = app.Settings.get 'confirm_unsaved_close'
      unsavedTabs = @editor.getUnsavedTabs()
      return unless unsavedTabs.length && confirm_unsaved_close
      fileNames = _.map unsavedTabs, (tab) -> tab.get 'name'
      'You have unsaved changes in file(s): ' + fileNames.join(', ') + '. Closing the window will destroy the changes.'

    checkUnsavedFiles: (cb) ->
      confirmUnsavedClose = app.Settings.get 'confirm_unsaved_close'
      return unless @editor
      unsaved = @editor.getUnsavedTabs()
      unless unsaved.length && confirmUnsavedClose
        cb()
        return false
      names = _.map unsaved, (tab) -> tab.get 'name'
      require ['lib/views/ui/popup'], (Popup) =>
        new Popup
          msg: 'You have unsaved changes in file(s): ' + names.join(', ') + '. Do you want to save those changes?'
          buttons: [
            (id:'no', txt: 'Don\'t save', exec: => cb())
            (id:'cancel', txt: 'Cancel', exec: => @editor.focus())
            (id:'yes', txt: 'Save all', highlight: true, exec: => @editor.saveAll => cb())
          ]
      return true

    onStartupData: (data) ->
      @startupData = data
      @editor?.tabs.each (tab) -> @tab.tryLoadStartupData()

    backupData: ->
      unsavedData = @editor?.tabs.map (tab) ->
        url: tab.get 'url'
        position: tab.session.selection.getCursor()
        data: tab.session.getValue()
        scrollTop: tab.session.getScrollTop()
        scrollLeft: tab.session.getScrollLeft()
      app.socket.emit 'backup', unsavedData if unsavedData.length


    openFile: (url, selector=null, index=0,  property=null) ->
      @editor.openFile url, selector, index, property

    getCurrentFile: ->
      @editor?.tabs.selectedTab()?.get 'url'

    isLiveMode: ->
      !!@project.get 'mode'

    onResize: ->
      @outline.onResize()
      @editor.onResize()


    onClientConnectedChange: (client) ->
      @activateConsole() if client.get 'connected'

    onClientRemoved: (client) ->
      _.delay => # Wait until client is actually removed.
        clients = @project.getClients()
        if clients.length
          app.router.navigate '' + clients[0].get('session_id'), trigger: true
        else
          app.router.navigate '' + @project.id, trigger: true

    unloadClient: ->
      if @client
        @client.off 'change:connected', @onClientConnectedChange, @
        @client.off 'remove', @onClientRemoved, @
        @clearElementPseudos()
        @clearClientMedia()
        @callClient 'setMedia', value: 'screen', ->

    loadClient: (client) ->
      @_wasSilentRefresh = false
      @clientPicker.select client
      @clientPicker2.select client

      if client
         @$('.sidebar').removeClass 'no-clients'
      else
         @outline.setTreeData []
         @styleInfo.setStyleData 0, [], []
         @$('.sidebar').addClass 'no-clients'

      @unloadClient()

      @client = client
      @client?.on 'change:connected', @onClientConnectedChange, @
      @client?.on 'remove', @onClientRemoved, @
      @renderEmbedMode()

      @activateConsole()
      

    onClientChange: (client) ->
      return if !client || client?.id == @client?.id
      app.router.navigate '' + client.get('session_id'), trigger: true
      @trigger 'change:client'

    onFocusedSelectorChange: (selector, selectFirst = false) ->
      @focusedSelector = selector
      console.log 'selectorchange', selector
      @elementsForSelector selector, (ids) =>
        console.log 'done'
        @outline.highlight ids
        @focusedSelectorElements = ids
        @outline.select ids[0] if (selectFirst or @state.get('outlineLock')) and ids.length
        @processFocus()
        @trigger 'change:focusedselector'

    processFocus: ->
      selectedId = @outline.selectedId()
      dfocus = @$('.editor-info > .selected-rule')
      
      dfocus.addClass 'is-visible'
      dselector = dfocus.find('.selector')
      dinfo = dfocus.find('.selector-elements')
      dhint = dfocus.find('.selection-hint')
      dhintinner = dhint.find('.inner')
      dselector.empty()
      dselector.append if @focusedSelector then highlightSelector @focusedSelector else ''
      haselements = !!@focusedSelectorElements?.length
      if haselements
        dinfo.show()
        dhint.show()
        index = @focusedSelectorElements.indexOf selectedId
        key = if ua.isMac then '⌘I' else 'Ctrl-I'
        if index == -1
          dinfo.text @focusedSelectorElements.length + ' element' + (if @focusedSelectorElements.length > 1 then 's' else '') + ' match' + (if @focusedSelectorElements.length > 1 then '' else 'es')
          dhintinner.text "#{key} to select"
          dfocus.closest('.infobar').removeClass 'is-binded'
        else
          dfocus.closest('.infobar').addClass 'is-binded'
          if @focusedSelectorElements.length == 1
            dinfo.text 'selected'
            dhint.hide()
          else
            dinfo.text "#{index+1} of #{@focusedSelectorElements.length}"
            dhintinner.text "#{key} for next"
      else
        dinfo.text 'No elements match'
        dhint.hide()
        dinfo.hide()
        dfocus.closest('.infobar').removeClass 'is-binded'

      unless @focusedSelector
        dfocus.removeClass 'visible'
        dfocus.closest('.infobar').removeClass 'is-binded'


    selectFocusedSelectorElement: (reverse=false) ->
      return unless @focusedSelector && @focusedSelectorElements?.length

      index = @focusedSelectorElements.indexOf @outline.selectedId()
      if index == -1 || @focusedSelectorElements.length == 1
        @outline.select @focusedSelectorElements[0]
      else
        if reverse then index-- else index++
        index = @focusedSelectorElements.length - 1 if index < 0
        index = 0 if index >= @focusedSelectorElements.length
        @outline.select @focusedSelectorElements[index]



    onElementSelected: (i) ->
      @serializeElement i.id, (selector) =>
        @state.save selectedItem: selector or null

        @trigger 'load:selector', i.id, selector
        @selector = selector
        @getStyles i.id
        if (@_wasSelectFromInspect && !@state.get 'leftPaneVisible') || i.openFirst
          @styleInfo.openStyleAtIndex 0
        @_wasSelectFromInspect = false

      @callClient 'showInspectArea', id: i.id unless @_dontInspectOutline
      @_dontInspectOutline = false
      @processFocus()
  
    onOutlineLoaded: ->
      @initPseudos ->
      @initFolds =>
        if (selectedItem = @state.get 'selectedItem') != null
          @unserializeElement selectedItem, (id) =>
            if id == -1 && @_wasSilentRefresh == true
              @callClient 'getLastStyledElement', {}, (resp) =>
                @selectElement resp.lastStyledElement
            else
              @selectElement id
        else
          @selectElement -1

    selectElement: (elementId) ->
      @_dontInspectOutline = true
      if elementId != -1
        @outline.select elementId, false
      else
        @outline.selectAt 0
      @outline.restoreScrollPosition()

    serializeElement: (elementId, cb) ->
      @callClient 'serializeElement', id: elementId, (resp) -> cb resp

    unserializeElement: (selector, cb) ->
      @callClient 'unserializeElement', selector, (resp) ->
        cb if resp then resp.id else -1

    selectParentAtIndex: (index) ->
      @outline.selectParent index if index

    elementsForSelector: (selector, cb) ->
      if @client
        @callClient 'elementsForSelector', selector:selector, (data) -> cb data.ids
      else
        _.defer -> cb null

    getStyles: (id) ->
      @callClient 'getStyles', id: id, (resp) =>
        @styleInfo.selectedElement = id
        @styleInfo.setStyleData id, resp.styles, resp.nearby, @selector
        rules = ([sdata.file, sdata.selector] for sdata in resp.styles when sdata.file)
        @trigger 'load:styles', id, rules
        @processFocus()
        @editor.highlight rules
        @$el.removeClass 'no-client-loaded'

    onStylesChanged: (data) ->
      if @styleInfo.selectedElement == data.id
        @serializeElement data.id, (selector) =>
          @styleInfo.setStyleData data.id, data.styles, data.nearby, selector

    getMedia: ->
      @media || 'screen'

    setMedia: (@media) ->
      @trigger 'change:media'
      @callClient 'setMedia', {value: @media}, ->
    
    clearClientMedia: ->
      @callClient 'setMedia', {value: 'screen'}, ->
        
    ## Fake pseudo-classes management.
    initPseudos: (cb) ->
      unless @pseudos
        @pseudos = new PseudoList null, backend: 'pseudos-' + @project.id
        @pseudos.on 'change', (pseudo) => @trigger 'change:pseudo', pseudo
      @pseudos.fetch success: =>
        return cb() unless @pseudos.size()
        parallel @pseudos.toArray(), (pseudo, done) =>
          @unserializeElement pseudo.get('selector'), (id) =>
            if id == -1 || !pseudo.get('pseudos').length
              pseudo.destroy()
            else
              pseudo.elementId = id
              @trigger 'change:pseudo', pseudo
            done()
        , => cb()

    setPseudoValue: (id, dataClass, bool) ->
      pseudo = @pseudos.find (p) -> p.elementId == id
      if pseudo
        classes = pseudo.get('pseudos')
        bool ?= !_.include classes, dataClass
        if bool
          pseudo.save pseudos: _.union classes, dataClass
        else
          pseudo.save pseudos: _.without classes, dataClass
      else if bool != false
        @serializeElement id, (data) =>
          @pseudos.create (selector: data, pseudos: [dataClass]), wait: true, success: (pseudo) =>
            pseudo.elementId = id
            @trigger 'change:pseudo', pseudo

    setElementPseudo: (id, pseudos) ->
      @callClient 'setElementPseudo', id: id, pseudos: pseudos, => @getStyles @outline.selectedId()

    clearElementPseudos: ->
      @callClient 'clearPseudos', {}, ->

    ## Outline folds management.
    initFolds: (cb) ->
      @folds = new FoldList null, backend: 'folds-' + @project.id
      @folds.fetch success: =>
        return cb() unless @folds.size()
        parallel @folds.toArray(), (f, done) =>
          @unserializeElement f.toJSON(), (id) =>
            if id == -1
              f.destroy()
            else
              if -1 != index = @outline.getIndex id
                if f.get('type') == 'fold'
                  @outline.foldAt index, true
                else
                  @outline.unfoldAt index, true
            done()
        , cb

    getFold: (data) ->
      @folds.find (f) ->
        data && data.selector == f.get('selector') and data.length == f.get('length') and data.index == f.get('index')

    onFold: (item) ->
      @serializeElement item.id, (data) =>
        if data && !@getFold data
          data.type = 'fold'
          @folds.create data

    onUnfold: (item) ->
      @serializeElement item.id, (data) =>
        if data
          if f = @getFold data
            f?.destroy()
          else
            data.type = 'unfold'
            @folds.create data



    callAPI: (name, params, cb) ->
      return unless @active
      app.socket.emit 'callAPI', name, params, cb

    callClient: (name, param, cb) ->
      return unless @client?.get 'connected'
      if @usesPostMessage
        @callClientPostMessage name, param, cb
      else
        app.socket.emit 'callclient', @client.id, name, param, cb

    callClientPostMessage: (name, param, cb) ->
      window.opener?.postMessage? (name: name, param: param, callbackId: @getPostMessageId cb), @project.get('baseurl')
    
    getPostMessageId: do ->
      callbacks = {}
      receive = (e) ->
        data = e.data
        return if data?.name != 'messageResponse'
        id = data?.callbackId
        if id
          [func, view] = callbacks[id]
          func? data.data if (view.project.get('baseurl').indexOf e.origin) == 0
      window.addEventListener 'message', receive, false
      (func) ->
        id = ~~ (Math.random() * 1e8)
        # TODO: Remove passing in view.
        callbacks[id] = [func, this]
        return id

    onClientMessage: (name, data) ->
      switch name
        when 'inspect'
          @onInspectorResult data
        when 'change:styles'
          @onStylesChanged data
        when 'change:dom'
          @_wasSilentRefresh = true
          @outline.setTreeData data.tree
        when 'change:media'
          @setMedia data.media

  module.exports = ConsoleView