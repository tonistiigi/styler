define (require, exports, module) ->

  {EditSession} = require 'ace/edit_session'
  {Anchor} = require 'ace/anchor'
  {Range} = require 'ace/range'

  {UndoManager} = require 'ace/undomanager'

  Tab = Backbone.Model.extend

    defaults: ->
      offset: 10000
      saved: true

    initialize: ->
      _.bindAll @, 'selectionchange', 'filedidchange', 'showCompletions', 'onManagerUpdate', 'onLoaded', 'tryCompletion'

      @on 'destroy', @onRemove, @

      @session = new EditSession ''

      @filedidchange() #load in contents

      project = app.console.project #todo: same lines appear in editorview
      @session.setUseSoftTabs project.get 'softTabs'
      @session.setTabSize project.get 'tabSize'
      @session.setUseWrapMode true

      @session.doc.on 'change', => @set saved: false

      @session.on 'stats', (stats) =>
        app.stats?.addStats (@get 'url'), stats

      @tryCompletionDebounced = _.throttle (=> _.delay @tryCompletion), 100

      #todo: seems hacky. is here because backspace fires selectionchange but doesn't change document
      @session.selection.selectionLead.on 'change', (e) =>
        if e.old.row == @session.selection.getCursor().row
          @tryCompletionDebounced() if (@get 'editor').completer?.active || app.Settings.get 'autocomplete'
        else
          @selectionchange()
          (@get 'editor').completer?.disable()

      file = @get 'file'
      file.on 'change:mtime', @filedidchange
      file.save edit: true

      @set lastSelectTime: new Date()

    tryLoadStartupData: ->
      return unless app.console.startupData
      data = _.find app.console.startupData, (data) => (data.url) == @get 'url'
      return unless data

      @session.setValue data.data if @session.getValue() != data.data
      @session.selection.clearSelection()
      @session.selection.moveCursorTo data.position.row, data.position.column
      @session.setScrollLeft data.scrollLeft
      @session.setScrollTop data.scrollTop

      app.console.startupData = _.without app.console.startupData, data

    onManagerUpdate: ->
      @selectionchange()
      @highlightSelectors()

    onLoaded: ({data})->
      @session.doc.setValue data
      @session.selection.setSelectionAnchor 0, 0
      @session.selection.moveCursorTo 0, 0
      @set saved: true

      unless @_loaded
        @session.setUndoManager new UndoManager()
        if 'stylus' == @get('file').get 'type'
          require ['lib/editor/stylus'], (StylusMode) =>
            @modeStylus ?= new StylusMode.Mode()
            @session.setMode @modeStylus
            _.delay =>
              require ['lib/editor/stylusmanager'], (StylusManager) =>
                @contentManager = new StylusManager @
                @contentManager.on 'update', @onManagerUpdate
                @contentManager.on 'loaded', =>
                  @selectSelector @_initialSelector... if @_initialSelector
            , 200
        else
          require ['lib/editor/css'], (CSSMode) =>
            @modeCSS ?= new CSSMode.Mode()
            @session.setMode @modeCSS
            _.delay =>
              require ['lib/editor/cssmanager'], (CSSManager) =>
                @contentManager = new CSSManager @
                @contentManager.on 'update', @onManagerUpdate
                @contentManager.on 'loaded', =>
                  @selectSelector @_initialSelector... if @_initialSelector
            , 200

        @tryLoadStartupData()

        @_completionCursor = 0
        _.delay =>
          require ['lib/editor/autocompleter'], (autoCompleter) => @autoCompleter = autoCompleter
        , 300
      @_loaded = true

    filedidchange: ->
      return @_rememberedSelfSave = false if @_rememberedSelfSave
      app.console.callAPI 'GetFileData', url: (@get 'url'), @onLoaded

    onRemove: ->
      @get('file').off 'change:mtime', @filedidchange

    selectionchange: ->
      pos = @session.selection.getCursor()
      error = @get 'error'
      if @contentManager?.complete
        @session.removeMarker @marker
        @selector = null #todo: bad naming

        rule = @contentManager.ruleForLine pos.row + 1
        if rule != -1
          {start, end} = @contentManager.rangeForRule rule
          if end >= pos.row
            @selector = rule
            @marker = @session.addMarker new Range(start - 1, 0, end, 0), 'selection-marker', 'line', true

            {editor} = @get 'editor'
            first = editor.getFirstVisibleRow()
            last = editor.getLastVisibleRow()

            if @_scrollcenter && (start - 2 < first or start + 4 > last)
              #move selector to center if clicked on (not moved) and it does not already appear in the middle area of the screen
              editor.scrollToLine start - ~~((last - first) / 4)
            else
              if first > start
                editor.scrollToLine start - 1
              else if end > last
                editor.scrollToLine first + end - last + 3

            selector = @contentManager.selectorTextForRule rule
          else
            selector = null
        else
          selector = null

        if @_currentSelector != selector and @get 'selected'
          @trigger 'selectorchange', selector
          @_currentSelector = selector


        @_scrollcenter = false

    showCompletions: (cursor, completions) ->
      #console.log 'showcompl', completions
      editor = @get 'editor'
      return editor.completer?.disable() if !completions
      return unless @_completionCursor == cursor
      {row, column} = @session.selection.getCursor()
      return unless @session.getLength() > row
      editor.completer?.activate @, completions, row, column

    tryCompletion: (force = false) -> #todo: force is not implemented
      return if app.console.dialogOpen
      #console.log 'try-completion'
      return unless @contentManager?.complete and @autoCompleter?
      cursor = @session.selection.getCursor()
      tokens = (@session.getTokens cursor.row, cursor.row)[0].tokens
      return if (_.find tokens, (t) -> t.type == 'comment')
      req = @contentManager.completionAtPosition cursor
      if req
        @autoCompleter.complete @get('file').get('type'), req, (_.bind @showCompletions, @, ++@_completionCursor)
      else
        (@get 'editor').completer?.disable()

    selectValueArea: (completion) ->
      position = @session.selection.getCursor()
      line = @session.doc.getLine position.row
      match = line.match /^((\s*([a-z-]{4,})\s*:?\s*).+?)\s*;?\s*$/
      return unless match
      propname = match[3].toLowerCase()
      return if propname in ['strong', 'span', 'table', 'tbody', 'input', 'textarea']
      @session.selection.setSelectionRange new Range(position.row, match[2].length, position.row, match[1].length)

    selectNewValuePosition: ->
      return unless @contentManager?.complete and @autoCompleter?
      position = @session.selection.getCursor()
      rule = @contentManager.ruleForLine position.row + 1
      return if rule == -1
      {start, end} = @contentManager.rangeForRule rule
      return if end < position.row
      end--
      line = @session.doc.getLine end
      if line.match /^\s*}\s*$/
        end--
      while true
        line = @session.doc.getLine end
        if end<=start or !line.match /^\s*$/
          break
        end--

      currentline = @session.doc.getLine end
      indent = (currentline.match /^\s*/)[0]
      nextline = @session.doc.getLine end + 1

      return if currentline.match /}\s*$/

      if nextline.match /^\s*$/
        @session.doc.replace new Range(end + 1, 0, end + 1, nextline.length), indent
        @session.selection.clearSelection()
        @session.selection.moveCursorTo end+1, indent.length
      else
        @session.doc.insert row:end, column:currentline.length, "\n#{indent}"
        @session.selection.clearSelection()
        @session.selection.moveCursorTo end+1, indent.length

    complete: (completion) ->
      position = @session.selection.getCursor()
      if completion.exec
        return completion.exec @get('editor'), position
      #completion.insert @, position
      #return
      line = @session.doc.getLine position.row
      isend = (line.substr position.column).match /^\s*$/
      data = completion.value
      if isend and completion.property #logic for these should be in function reference
        if @get('file').get('type') == 'stylus'
          data += ' '
        else
          data += ': '
      if completion.sfx
        data += completion.sfx
      if completion.pfx
        data = completion.pfx + data
      @session.doc.replace new Range(position.row, position.column - completion.offset, position.row, position.column + (completion.padd || 0)), data
      if completion.cursor
        @session.selection.moveCursorBy 0, completion.cursor
      if !isend and completion.property
        position = @session.selection.getCursor()
        line = @session.doc.getLine position.row
        lastpart = line.substr position.column
        m = lastpart.match /^[\s:]+/
        if m
          @session.selection.moveCursorBy 0, m[0].length
          endpos = line.length
          endpos-- if line[endpos - 1] == ';'
          @session.selection.setSelectionAnchor position.row, endpos

    selectSelector: (selector, index=0, property=null) ->
      unless @contentManager?.complete
        return @_initialSelector = [selector, index, property]
      rule = @contentManager.ruleForSelectorText selector, index
      if rule != -1
        @_scrollcenter = true
        @markSelector rule, property

    close: ->
      if not @get "saved"
        app.console.callAPI 'PublishSaved', url: (@get 'url')

      file = @get 'file'
      file.save edit: false
      @destroy()

    tryClose: ->
      if @get 'saved'
        @close()
      else
        require ['lib/views/ui/popup'], (Popup) =>
          new Popup
            msg: "Do you want to save the changes you made in file \"#{@get('name')}\"?"
            buttons: [
              (id: 'no', txt: 'Don\'t save', exec: => @close())
              (id: 'cancel', txt: 'Cancel', exec: => @get('editor').focus())
              (id: 'yes', txt: 'Save', highlight: true, exec: => @get('editor').save @, => @close())
            ]

    moveSelector: (delta) ->
      if @selector
        rule = @selector #todo: rename @selector -> @rule
      else
        rule = @contentManager.ruleForLine @session.selection.getCursor().row + 1

      #return if rule == -1

      if delta == -1
        rule = @contentManager.previousRule rule - 1 if @selector
      else
        rule = @contentManager.nextRule rule
      return if rule == -1

      @markSelector rule

    markSelector: (rule, property = null) ->
      return unless @contentManager?.complete

      pos = null
      if property
        properties = [property]
        if property.match /^\-[a-z]+\-/i
          parts = property.split '-'
          parts = parts.slice 2
          properties.push parts.join '-'

        {start,end} = @contentManager.rangeForRule rule
        while start <= end
          row = @session.doc.getLine start
          for property in properties
            match = row.match new RegExp('^\\s*' + property, 'i')
            if match
              pos = row: start, col: 0
              m = row.match /^\s*[^\s:]+\s*:?\s*/
              if m
                pos.col = m[0].length
                lastcol = row.length
                lastcol -= mm[0].length if mm = row.match /;\s*$/

                @session.selection.setSelectionAnchor start, lastcol
                @session.selection.moveCursorTo start, pos.col
                return
          start++

      unless pos
        row = @session.doc.getLine rule - 1
        pos = row: rule - 1, col: (row.match /^\s*/)[0].length

      @session.selection.moveCursorTo pos.row, pos.col
      @session.selection.setSelectionAnchor pos.row, pos.col


    highlightSelectors: (selectors = null) ->
      return unless @contentManager?.complete

      doc = @session.doc
      @hlselectors = selectors if selectors != null
      if @hlmarkers
        for m in @hlmarkers
          m[0].detach()
          m[1].detach()
          @session.removeMarker m[2]
      @hlmarkers = []
      if @hlselectors
        for [file,selector] in @hlselectors
          rule = @contentManager.ruleForSelectorText selector
          continue if rule == -1
          {start, end} = @contentManager.rangeForRule rule
          anchor_start = new Anchor doc, start - 1, 0
          anchor_end = new Anchor doc, end, 0
          m = [anchor_start, anchor_end, @session.addMarker (Range.fromPoints anchor_start.getPosition(), anchor_end.getPosition()), 'highlight-marker', 'line', false]
          @hlmarkers.push m
          anchor_start.marker = m
          anchor_end.marker = m
          reposition = _.bind @repositionHighlight, @, anchor_start
          anchor_start.on 'change', reposition
          anchor_end.on 'change', reposition
          #todo: is there a way to avoid double change event
      @trigger 'change:highlight'

    # helper that repositions the highlight after content change based on
    # the ace/anchors without parsing the contents
    repositionHighlight: (anchor) ->
      [start, end, marker] = anchor.marker
      @session.removeMarker marker
      anchor.marker[2] = @session.addMarker (Range.fromPoints start.getPosition(), end.getPosition()), 'highlight-marker', 'line', false

    select: ->
      isselected = !! @get 'selected'
      return if isselected
      @collection.each (t) ->
        t.set 'selected': false if !! t.get 'selected'
      @set 'selected': true
      @set 'lastSelectTime': new Date()
      @trigger 'select', @
      @trigger 'selectorchange', @_currentSelector
      app.console?.state.save selectedUrl: @get('url'), selectedType: @get('file').get('type')

  TabList = Backbone.Collection.extend
    model: Tab
    listen: -> #overwrite now

    initialize: ->
      @on 'remove', @resetSelected, @

    comparator: (tab) ->
      tab.get 'offset'

    selectedTab: ->
      @find (t) -> t.get 'selected'

    resetSelected: ->
      if @size()
        tab = @max (t) -> t.get 'lastSelectTime'
        tab.select()
      else
        @trigger 'empty'

  Tab: Tab
  TabList: TabList
