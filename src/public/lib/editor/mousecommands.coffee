define (require, exports, module) ->
  {Range} = require 'ace/range'
  ua = require 'ace/lib/useragent'
  {combineUrl, node, hexToRgb} = require 'lib/utils'
  {listenKey} = require 'lib/keyboard'

  MouseCommands = Backbone.View.extend

    className: 'editor-command-highlight'

    initialize: (opt) ->
      _.bindAll @, 'onActivationKeyDown', 'onActivationKeyUp', 'onContainerMouseMove', 'onMouseDown', 'onNumericMouseMove', 'onNumericMouseUp', 'onMouseMove', 'onMouseWheel'

      @editor = opt.editor

      @editor.navigateUpDown = (delta) ->
        document = @getSession()?.doc
        return unless document
        @selection.clearSelection()
        cursor = @selection.getCursor()
        line = document.getLine cursor.row
        indent = (line.match /^\s*/)[0].length
        offset = 0
        if cursor.column == indent
          nextLine = document.getLine cursor.row + delta
          nextIndent = nextLine.match(/^\s*/)[0].length
          offset = nextIndent - indent
        @selection.moveCursorBy delta, offset

      @editor.navigateUp = (times) ->
        times = times || 1
        @navigateUpDown -times

      @editor.navigateDown = (times) ->
        times = times || 1
        @navigateUpDown times

      listenKey 'editor', 'numeric-increment', exec: => @offsetNumeric 1
      listenKey 'editor', 'numeric-decrement', exec: => @offsetNumeric -1
      listenKey 'editor', 'numeric-increment-many', exec: => @offsetNumeric 10
      listenKey 'editor', 'numeric-decrement-many', exec: => @offsetNumeric -10

      @commandKey = (if ua.isMac then (if ua.isGecko then 224 else 91) else 17)
      @activated = false
      @action = {}

      $(window).on('keydown', @onActivationKeyDown).on('keyup', @onActivationKeyUp)

      @$el.on('mousedown', @onMouseDown).on('mousemove', @onMouseMove)

      @editor.addEventListener 'mousewheel', @onMouseWheel

    onActivationKeyDown: (e) ->
      if e.keyCode == @commandKey && app.isEditorMode && !@activated
        @activated = true
        $(@editor.container).on 'mousemove', @onContainerMouseMove

    onActivationKeyUp: (e) ->
      if @activated && (e == true || e.keyCode == @commandKey)
        @activated = false
        $(@editor.container).off 'mousemove', @onContainerMouseMove
        @stopCommand()

    showCmdHighlight: (coord, match, type) ->
      @action = coord: coord, match: match, type: type
      editorPosition = @editor.container.getBoundingClientRect()
      pxcoord = @editor.renderer.textToScreenCoordinates coord.row, match.offset

      @$el.toggleClass('is-selectable', type != 'numeric').css
        left: pxcoord.pageX - editorPosition.left
        top: pxcoord.pageY - editorPosition.top
        width: match.match.length * @editor.renderer.characterWidth
        height: @editor.renderer.lineHeight
        display: 'block'
      @visible = true
      @lastUrl = null if type != 'url'

    startCommand: (coord) ->
      if match = @checkValidNumeric coord
        @showCmdHighlight coord, match, 'numeric'
      else if match = @checkValidPattern coord, /#[0-9a-f]{3,6}(?:\b|;|$)/ig
        @showCmdHighlight coord, match, 'color'
      else if match = @checkValidPattern coord, /url\([a-z0-9"'\/\\\.@_-]+\)/ig
        @showCmdHighlight coord, match, 'url'
      else if @visible
        @stopCommand()

    onMouseWheel: (e) ->
      if e.domEvent.target == @el && @action.type == 'numeric'
        unless @action.wheelDelta?
          @action.stackPosition = @editor.session.getUndoManager().$undoStack.length
          @action.wheelDelta = 0
        @action.wheelDelta += e.wheelY
        @updateNumericValue (Math.floor @action.wheelDelta * if e.domEvent.shiftKey then 3 else .25)
        e.stop()
      else
        @stopCommand()

    stopCommand: ->
      @action = {}
      @lastUrl = null
      @infoTip?.hide()
      @$el.hide()

    onContainerMouseMove: (e) ->
      return @onActivationKeyUp true unless (if ua.isMac then e.metaKey else e.ctrlKey)
      return if @action.type == 'numeric' && @action.lastScrollOffset?
      @startCommand @editor.renderer.screenToTextCoordinates e.pageX, e.pageY

    onMouseDown: (e) ->
      return unless @activated && !e.button
      switch @action.type
        when 'color'
          @startColorPicker @action.match, @action.coord
          @stopCommand()
        when 'url'
          require ['lib/views/ui/imagepreview'], (ImagePreview) =>
            url = (@action.match.match.match /^url\(['"]?(.*?)["']?\)$/i)[1]
            fileurl = app.console.editor.tabs.selectedTab().get('url')
            new ImagePreview combineUrl fileurl, url
            @stopCommand()
        when 'numeric'
          return if @action.lastScrollOffset?
          $(window).on('mousemove', @onNumericMouseMove).on('mouseup', @onNumericMouseUp)
          $(document).on 'selectstart', @preventDefault
          @action.lastScrollOffset = e.pageY
          @action.stackPosition = @editor.session.getUndoManager().$undoStack.length

      e.stopPropagation()
      e.preventDefault()

    onNumericMouseMove: (e) ->
      delta = e.pageY - @action.lastScrollOffset
      @updateNumericValue (Math.floor delta * if e.shiftKey then 2 else .2)

    onNumericMouseUp: ->
      $(window).off('mousemove', @onNumericMouseMove).off('mouseup', @onNumericMouseUp)
      $(document).off 'selectstart', @preventDefault
      delete @action.lastScrollOffset

    preventDefault: (e) ->
      e.stopPropagation()
      e.preventDefault()

    updateNumericValue: (delta) ->
      return unless @action.type == 'numeric'
      {stackPosition, match, coord} = @action
      {session} = @editor
      newValue = (match.value + delta * Math.pow(10, -match.presicion)).toFixed(match.presicion)
      session.getUndoManager().undo(true) while stackPosition < session.getUndoManager().$undoStack.length
      @editor.session.selection.clearSelection()
      @editor.session.selection.moveCursorTo coord.row, coord.column
      replaced = @replaceNumeric coord, match, newValue
      @editor.session.$syncInformUndoManager()
      @$el.css width: replaced.length * @editor.renderer.characterWidth

    startColorPicker: (match, coord) ->
      stackPosition = @editor.session.getUndoManager().$undoStack.length
      popup = window.open '', 'colorpicker', 'width=410,height=300,resizable=no,scrollbars=no'
      $(popup.document.body).css overflow: 'hidden', margin: 0, background: '#444'
      popup.document.title = 'Color picker'
      app.console.dialogOpen = true
      # Without defer firefox doesn't preventDefault() for event??
      _.defer =>
        if match == false
          match = @checkValidPattern coord, /[^\s;]+/ig
          match = match: '', offset: coord.column unless match

        require ['vendor/colorpicker'], (colorPicker) =>
          colorPicker.cP = null
          colorPicker.exportColor = =>
            value = colorPicker.CP.hex
            return if value == lastValue
            lastValue = value
            value = value.toLowerCase()
            if value[0] == value[1] && value[2] == value[3] && value[4] == value[5]
              value = value[0] + value[2] + value[4]
            @editor.session.getUndoManager().undo(true) while stackPosition < @editor.session.getUndoManager().$undoStack.length
            @editor.session.selection.clearSelection()
            @editor.session.selection.moveCursorTo coord.row, coord.column
            @editor.session.doc.replace new Range(coord.row, match.offset, coord.row, match.offset + match.match.length), '#' + value
            @editor.session.$syncInformUndoManager()
          colorPicker.saveColor = -> popup.close()
          startValue = '#000'
          startValue = match.match if match.match[0] == '#' && match.match.length in [4, 7]
          colorPicker null, 'H', 4, false, false, false, false, true, 0, 3, ['top', 'left'], popup.document.body, '', startValue.toUpperCase(), 2, 15, 0, popup.document.body, popup.document
          lastValue = match.match.substr 1
          $(popup.document)
            .on('blur', -> popup.close())
            .on('unload', -> app.console.dialogOpen = false)
            .on 'keydown', (e) =>
              if e.keyCode == 27
                @editor.session.getUndoManager().undo(true) while stackPosition < @editor.session.getUndoManager().$undoStack.length
                popup.close()
              popup.close() if e.keyCode == 13

    onMouseMove: (e) ->
      return unless @activated && @action.type != 'numeric'
      switch @action.type
        when 'url'
          url = (@action.match.match.match /^url\(['"]?(.*?)["']?\)$/i)[1]
          return if url == @lastUrl
          @lastUrl = url
          fileurl = app.console.editor.tabs.selectedTab().get('url')
          url = combineUrl fileurl, url
          require ['lib/views/ui/infotip', 'lib/views/ui/imagepreview'], (infoTip, ImagePreview) =>
            @infoTip = infoTip
            infoTip.showPanel e, 130, 100, (cb) ->
              ImagePreview.getPreviewElement url, 120, 70, (err, el) ->
                return if err
                cb el

        when 'color'
          color = @action.match.match
          require ['lib/views/ui/infotip', 'vendor/colorpicker'], (infoTip, colorPicker) =>
            @infoTip = infoTip
            infoTip.showPanel e, 80, 40, (cb) ->
              rgb = hexToRgb color
              cb node 'div', class: 'colorinfo',
                node 'div', class: 'sample', style: backgroundColor: color
                node 'div', class: 'values',
                  node 'div', 'R: ' + rgb[0]
                  node 'div', 'G: ' + rgb[1]
                  node 'div', 'B: ' + rgb[2]



    offsetNumeric: (delta=1) ->
      return unless session = @editor.getSession()

      cursor = session.selection.getCursor()

      if found = @checkValidNumeric cursor
        @replaceNumeric cursor, found, (found.value + delta * Math.pow(10, -found.presicion)).toFixed(found.presicion)
        session.selection.setSelectionAnchor cursor.row, cursor.column
        session.selection.moveCursorTo cursor.row, cursor.column

      if event
        event.stopPropagation()
        event.preventDefault()

    checkValidPattern: (cursor, regexp) ->
      session = @editor.getSession()
      line = session.getLine cursor.row
      found = null
      line.replace regexp, (match, offset) ->
        if offset <= cursor.column && offset + match.length >= cursor.column
          return found = match: match, offset: offset
      found

    checkValidNumeric: (cursor) ->
      match = @checkValidPattern cursor, /-?[\d\.]+(?:px|em|ex|cm|mm|in|pt|pc|deg|rad|grad|ms|s|hz|khz|%)(?=\W|$)/ig
      if match
        firstpart = match.match.match(/-?[\d\.]+/)[0]
        match.presicion = firstpart.split('.')[1]?.length || 0
        match.len = firstpart.length
        match.value = parseFloat firstpart
      match

    replaceNumeric: (cursor, match, newValue) ->
      session = @editor.getSession()
      newValue += match.match.substr match.len
      session.doc.replace new Range(cursor.row, match.offset, cursor.row, match.offset + match.match.length), newValue
      return newValue

    destroy: ->


  module.exports = MouseCommands