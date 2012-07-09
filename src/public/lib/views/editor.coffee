define (require, exports, module) ->
  ace = require 'ace/ace'
  config = require 'ace/config'
  ua = require 'ace/lib/useragent'
  {listenKey, addKeyboardListener} = require 'lib/keyboard'

  FileBrowser = require 'lib/views/ui/filebrowser'
  {FileList} = require 'lib/models'
  ModeSwitch = require 'lib/views/ui/modeswitch'
  {TabList, Tab} = require 'lib/editor/tabs'
  {TabListView} = require 'lib/editor/tabviews'
  TabSwitch = require 'lib/views/ui/tabswitch'
  {parallel, node} = require 'lib/utils'

  require 'vendor/link!css/editorview.css'
  
  config.set 'packaged', !!window.__packaged

  EditorView = Backbone.View.extend

    template: require 'lib/templates/editor'

    initialize: ->
      _.bindAll @, 'openFileView', 'save'

      @$el.html @template()

      @$('.file-filter input').on 'change', (el) ->
        app.Settings.save activeonly: el.currentTarget.checked
      @$('.file-filter input').attr(checked: true) if app.Settings.get('activeonly')

      @tabs = new TabList
      @tabs.on 'empty', @openFileView, @
      new TabListView collection: @tabs, el: @$('.tabs')[0]

      @initializeEditor()

      @$('.tool-file-list').on 'click', @openFileView
      @$('.tool-save').on 'click', => @save()

      @$('.statusbar').append [new TabSwitch().el, new ModeSwitch().el]

      project = app.console.project
      project.on 'change:tabSize', @renderTabSize, @
      project.on 'change:softTabs', @renderTabSize, @

      app.Settings.on 'change:save_icon', @renderSaveIcon, @
      app.Settings.on 'change:statusbar', @renderStatusbar, @
      @renderSaveIcon()      
      @renderStatusbar()

      files = new FileList null, backend: 'files-' + app.console.project.id
      @filebrowser = new FileBrowser el: @$('.filebrowser')[0], collection: files
      files.fetch success: =>
        selectedUrl = app.console?.state?.get 'selectedUrl'
        hasSelectedTab = false
        files.chain()
          .filter((file) -> file.get 'edit')
          .sortBy((file) -> file.get 'offset')
          .each (file) =>
            url = file.get('url')
            isSelected = selectedUrl == url
            @openFile url, null, null, null, isSelected
            hasSelectedTab = true if isSelected
            
        @openFileView() unless hasSelectedTab


    initializeEditor: -> #todo: rename initEditor
      @editor = ace.edit @$('.editor')[0]

      addKeyboardListener 'editor', @editor.commands

      for i in [1..9]
        listenKey null, "tab-#{i}", mac: "command-#{i}", win: "ctrl-#{i}", exec: _.bind (i) ->
            @tabs.at(i - 1).select() if @tabs.length > i - 1
          , @, i

      listenKey null, 'select-filebrowser', exec: _.bind @openFileView, @
      listenKey null, 'save-tab', exec: => @save()
      listenKey null, 'save-all', exec: _.bind @saveAll, @

      listenKey null, 'close-tab', exec: => @closeTab()
      listenKey null, 'close-tab-native', mac: 'Command-W', win: 'Ctrl-W', exec: =>
        @closeTab() if ua.isGecko || ua.isWebKit && !ua.isChrome

      listenKey 'editor', 'focus-selector-up', exec: _.bind @moveSelectorUp, @
      listenKey 'editor', 'focus-selector-down', exec: _.bind @moveSelectorDown, @
      listenKey 'editor', 'indent-selection', exec: _.bind @editor.indent, @editor
      listenKey 'editor', 'outdent-selection', exec: _.bind @editor.blockOutdent, @editor

      listenKey 'editor', 'edit-value', exec: => @tabs.selectedTab()?.selectValueArea()
      listenKey 'editor', 'new-property', exec: => @tabs.selectedTab()?.selectNewValuePosition()
      listenKey 'editor', 'show-completions', exec: => @tabs.selectedTab()?.tryCompletion true

      @editor.commands.removeCommand 'find'
      @editor.commands.removeCommand 'findnext'
      @editor.commands.removeCommand 'findprevious'
      # TODO: Figure out what to do with next ones. Some may need it but they use same shortcuts.
      @editor.commands.removeCommand 'togglerecording'
      @editor.commands.removeCommand 'replaymacro'

      app.Settings.on 'change:invisibles', @renderInvisbles, @
      app.Settings.on 'change:line_numbers', @renderLineNumbers, @
      app.Settings.on 'change:theme', @renderTheme, @
      @renderInvisbles()
      @renderTheme()
      @renderLineNumbers()
      
      @editor.renderer.setShowPrintMargin false
      @editor.renderer.setHScrollBarAlwaysVisible false

      _.delay =>
        require ['lib/views/ui/completer', 'lib/editor/mousecommands', 'lib/views/ui/search'], (Completer, MouseCommands, Search) =>
          @completer = new Completer
          @editor.container.appendChild @completer.el

          @commands = new MouseCommands editor: @editor
          @editor.container.appendChild @commands.el

          new Search el: @$('.search')[0], editor: @
      , 200


    renderSaveIcon: ->
      @$('.icon.save').toggle !!app.Settings.get 'save_icon'

    renderStatusbar: ->
      @$('.statusbar').toggle !!app.Settings.get 'statusbar'

    renderLineNumbers: ->
      @editor.renderer.setShowGutter !!app.Settings.get 'line_numbers'

    renderInvisbles: ->
      @editor.renderer.setShowInvisibles !!app.Settings.get 'invisibles'

    renderTheme: ->
      @editor.setTheme 'ace/theme/' + app.Settings.get 'theme'

    renderTabSize: ->
      project = app.console.project
      @tabs.each (tab) ->
        tab.session.setUseSoftTabs project.get 'softTabs'
        tab.session.setTabSize project.get 'tabSize'

    openFileView: -> #todo: rename FileBrowser
      @$('.tool-file-list').addClass 'is-selected'
      @$('.tool-save').addClass 'is-disabled'
      if selectedTab = @tabs.selectedTab()
        selectedTab.set selected: false
      
      if app.console?  
        app.console.state.save selectedUrl: ''
        app.console.$el.removeClass 'is-editormode'
      if @filebrowser
        @filebrowser.el.focus()
      
      @trigger 'change:focusedselector', null
      app.isEditorMode = false

    focus: ->
      if @tabs.selectedTab()
        @editor.focus()
      else
        @filebrowser.el.focus()

    openEditorView: ->
      @editor?.resize()
      app.console?.$el.addClass 'is-editormode'
      @$('.tool-file-list').removeClass 'selected'
      app.isEditorMode = true

    getUnsavedTabs: (tabIndex = null) ->
      @tabs.select (tab, i) ->
        return (tabIndex == null || tabIndex == i) && !tab.get('saved')

    highlight: (selectors) ->
      @highlightRules = _.groupBy selectors, ([url, selector]) -> url
      @tabs.each (tab) =>
        url = tab.get 'url'
        tab.highlightSelectors if @highlightRules[url] then @highlightRules[url] else []

    moveSelectorUp: ->
      @tabs.selectedTab()?.moveSelector -1

    moveSelectorDown: ->
      @tabs.selectedTab()?.moveSelector 1

    onResize: ->
      @editor.renderer.onResize true
      
    save: (tab = null, callback = null) ->
      tab ?= @tabs.selectedTab()
      return unless tab?.session

      return callback?() if tab.get 'saved'

      tab._rememberedSelfSave = true
      app.console.callAPI 'SetFileData', url: tab.get('url'), data: tab.session.getValue(), (err) ->
        if err
          if err.code == 'EPERM'
            alert "Permission denied for saving changes to file '#{err.path}'. Please make sure this file can be changed by the system user that is running Styler."
          else
            alert "Could not save file to '#{err.path}'. Error #{err.code}(#{err.errno})."
        else
          tab.set saved: true
          callback?()
      

    saveAll: (cb = null) ->
      parallel @tabs.toArray(), (tab, cb2) =>
        @save tab, cb2
      , -> cb?()

    closeTab: (tab = null) ->
      tab ?= @tabs.selectedTab()
      return unless tab?.session
      tab.tryClose()

    onTabSelect: (tab) ->
      @editor.setSession tab.session
      @editor.focus()
      @openEditorView()
      @completer?.disable()
      @$('.tool-save').toggleClass 'is-disabled', tab.get 'saved'

    onTabSaved: (tab) ->
      if tab == @tabs.selectedTab()
        @$('.tool-save').toggleClass 'is-disabled', tab.get 'saved'

    openFile: (url, selector, index, property, select = true) ->
      tab = @tabs.find (t) -> url == t.get 'url'
      unless tab
        file = @filebrowser.collection.find (f) -> url == f.get 'url'
        return unless file

        tab = new Tab name: file.get('name'), url: url, editor: @, file: file
        tab.highlightSelectors if @highlightRules?[url] then @highlightRules[url] else []
        @tabs.add tab

        tab.on 'select', @onTabSelect, @
        tab.on 'change:saved', @onTabSaved, @
        tab.on 'selectorchange', (sel) => @trigger 'change:focusedselector', sel
        # TODO: These events are never cleared on destroy.

      tab.select() if select
      tab.selectSelector selector, index, property if selector
      _.delay => @editor.focus()

    destroy: ->
      project = app.console.project
      project.off 'change:tabSize', @renderTabSize, @
      project.off 'change:softTabs', @renderTabSize, @
      
      app.Settings.off 'change:save_icon', @renderSaveIcon, @
      @filebrowser?.destroy()
      @commands?.destroy()

      _.delay (=> @tabs.at(0).destroy() while @tabs.size()), 500
      
    formatCurrentFile: ->
      tab = @tabs.selectedTab()
      return unless tab
      if tab.get('url').match /css$/
        require ['vendor/cssbeautify'], ->
          project = app.console.project
          value = tab.session.getValue()
          softTabs = project.get 'softTabs'
          tabSize = project.get 'tabSize'
          tabstring = if softTabs then Array(tabSize + 1).join(' ') else '\t'
          value = cssbeautify value, indent: tabstring
          tab.session.doc.setValue value

  module.exports = EditorView