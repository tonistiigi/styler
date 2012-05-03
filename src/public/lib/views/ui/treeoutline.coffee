define (require, exports, module) ->

  require 'vendor/link!css/treeoutline.css'

  {addMouseWheelListener} = require 'ace/lib/event'
  ua = require 'ace/lib/useragent'
  {node, highlightSelector, style} = require 'lib/utils'
  {addKeyboardListener, listenKey} = require 'lib/keyboard'

  LINE_HEIGHT = 20
  INDENT = 11

  TreeOutline = Backbone.View.extend

    attributes:
      tabindex: 0
      
    className: 'elements-outline'

    events: ->
      'click .subtree-heading > .clear-subtree-btn' : 'clearSubtree'

    initialize: ->
      _.bindAll @, 'onItemClick', 'onResize', 'onScroll', 'saveScrollPosition'
      @edge = 0
      
      @saveScrollPosition = _.throttle @saveScrollPosition, 400

      @$el.append node 'div', class: 'subtree-heading',
        node 'div', class: 'clear-subtree-btn'
        node 'div', class: 'element-name'
      @$el.append node 'div', class: 'scroller-container',
          @scrollerEl = node 'div', class: 'scroller',
            @scrollerContentsEl = node 'div', class: 'items-container',
              @itemsEl = node 'div', class: 'items'

      $(@scrollerEl).on 'scroll', _.throttle @onScroll, if ua.isWebkit then 30 else 60
      $(@itemsEl).on 'click', @onItemClick
      $(window).on 'resize', @onResize
      
      app.console.bind 'change:pseudo', (pseudo) =>
        @setPseudoValue pseudo.elementId, pseudo

      addKeyboardListener 'outline', @el
      @el.listenKey 'select-next-element', exec: => @moveSelection 1
      @el.listenKey 'select-previous-element', exec: => @moveSelection -1
      @el.listenKey 'select-down-many', exec: => @moveSelection 10
      @el.listenKey 'select-up-many', exec: => @moveSelection -10
      @el.listenKey '_select-down-many', mac: 'pagedown', exec: => @moveSelection 10
      @el.listenKey '_select-up-many', mac: 'pageup', exec: => @moveSelection -10
      @el.listenKey 'select-last', mac: 'end', exec: => @moveSelection 1e6
      @el.listenKey 'select-first', mac: 'home', exec: => @moveSelection -1e6
      @el.listenKey 'fold-element', exec: => @unfoldAt @selectedIndex
      @el.listenKey 'unfold-element', exec: => @foldAt @selectedIndex
      @el.listenKey 'select-outline-subtree', exec: => @selectSubtree @selectedIndex
      @el.listenKey 'hide-outline-subtree', exec: => @selectSubtree()
      @el.listenKey 'focus-element-styleinfo', exec: => @trigger 'focus:styleinfo'

      listenKey null, 'scroll-to-view', exec: =>
        @scrollToIndex @selectedIndex if @selectedIndex != -1

      @selectedIndex = -1
      @setDirty()
      @onResize()

    # Marks from where offsets need to be recalculated before viewing.
    setDirty: (from = 0) ->
      # Boolean value clears
      if from == false
        @offsetDirty = false
        @dirtyFrom = undefined
      else
        @offsetDirty = true
        # only valid if first time or lower than previous mark
        if !@dirtyFrom? || from < @dirtyFrom
          @dirtyFrom = from

    _isEqualNode: (n1, n2) ->
      if n1 && n1?.name == n2?.name
        if n1.c?.length && n1.c?.length == n2.c?.length
          for i in [0...n1.c.length]
            break unless @_isEqualNode n1.c[i], n2.c[i]
          return true
      false

    _parseData: (data, indent = 0, parent = null) ->
      c = 0
      prevnode = null
      maxindent = indent
      isinline = true
      # TODO: fix naming for maxindent/inline
      for line in data
        mi = indent
        c++
        l = i: @lines.length, offset: @lines.length, indent: indent
        if typeof line == 'string'
          l.text = line
        else
          l.text = line.d if line.d
          l.name = line.n
          l.id = line.id
          l.c = line.c
          l.parent = parent
          line_inline = !!line.n.match /^(span|b|i|u|a|font|strong|p|img)\b/
          if isinline and !line_inline
            isinline = false
        @lines.push l
        if line.c
          {count, mi, inline} = @_parseData line.c, indent + 1, l
          maxindent = mi if mi > maxindent
          if isinline and !inline
            isinline = false
          c += l.count = count

        # Autofold rules.
        if @_isEqualNode(prev, l)
          l.autofold = true
        else if indent > 4 and (mi > indent && mi - indent < 4)
          l.autofold = true
        else if line_inline == false and inline && count > 5
          l.autofold = true
        prev = l
      count: c, mi: maxindent, inline: isinline

    _getLineName: (line) ->
      name = ''
      while line and name.length < 25
        name = line.name + ' ' + name
        line = line.parent
      name

    _updateOffsets: ->
      @offsets = []
      i = 0
      len = @lines.length
      while i < len
        line = @lines[i]
        first = 0
        if !@subtree? || (@subtree <= i && i<= @subtree + @lines[@subtree].count)
          offset = @offsets.length
          @offsets.push i
        else
          offset = -1
        line.offset = offset
        if line.fold
          j = i
          i = line.count + j + 1
          while ++j < i
            @lines[j].offset = -2
        else
          i++
      @setDirty false

    onResize: ->
      $(@scrollerEl).css height: height = @el.offsetHeight
      if height != @containerHeight
        @containerHeight = height
        if @scrollPosition
          isPositionedBySelection = @scrollPosition.selection
          @restoreScrollPosition()
          @scrollToIndex @selectedIndex if isPositionedBySelection
      @

    onScroll: (e) ->
      @scrollTo @scrollerEl.scrollTop

    moveSelection: (delta) ->
      # selectAt 0 is meaningless
      return @selectAt 0 unless @selectedIndex?
      offset = @getOffset @selectedIndex
      offset += delta
      @selectAt offset, delta < 0

    selectAt: (offset, moveTopIfNotFound = true, openFirstRule = false) ->
      @_updateOffsets() if @offsetDirty
      offset = 0 if offset < 0
      last = @offsets.length - 1
      offset = last if offset >= last
      index = @getIndexAt offset
      return if index == -1
      line = @lines[index]

      unless line.id?
        if moveTopIfNotFound
          if index == 0
            return @selectAt offset, false
          else
            return @selectAt offset - 1, true
        else
          if index == last
            return @selectAt offset, true
          else
            return @selectAt offset + 1, false
      @selectIndex index, true, openFirstRule

    selectIndex: (index, scroll = true, openFirstRule = false) ->
      return if index == -1
      if @selectedIndex?
        $(@lines[@selectedIndex].el).removeClass 'is-selected'

      offset = @getOffset index
      if offset == -1
        @clearSubtree()
        offset = @getOffset index
      if offset == -2
        l = @lines[index]
        while l
          @unfoldAt l.i if l.fold
          l = l.parent
        @_updateOffsets()

      @selectedIndex = index
      line = @lines[index]
      $(line.el).addClass 'is-selected'
      @trigger 'select', index: index, id: line.id, openFirst: openFirstRule
      if scroll
        @scrollToIndex index
        @storeScrollPosition()

    selectedId: ->
      return line.id if @selectedIndex != -1 && line = @lines[@selectedIndex]
      null

    selectParent: (level) ->
      if @selectedIndex != -1
        line = @lines[@selectedIndex]
        line = line?.parent while level-- > 0
        @selectIndex line.i if line

    select: (id, scroll = true) ->
      i = @getIndex id
      return @selectIndex i, scroll if i != -1

    onItemClick: (e) ->
      firstItemY = $(e.target).closest('.outline-item').get(0).offsetTop + (e.offsetY || e.layerY)
      offset = Math.floor(firstItemY / LINE_HEIGHT) + @scrollOffset
      @selectAt offset, true, e.detail == 2
      index = @getIndexAt offset
      if e.detail == 2 and @lines[index].c && @lines[index].fold == 1
        @unfoldAt index
      else if ($(e.target).hasClass 'fold-btn')
        if @lines[index].fold == 1
          @unfoldAt index
        else
          @foldAt index
      else if $(e.target).hasClass 'select-subtree-btn'
        @selectSubtree index

    highlight: (@highlightedItems) ->
      @onScroll() if @complete

    selectSubtree: (index) ->
      @subtree = index
      if @subtree?
        line = @lines[index]
        $(@itemsEl).css marginLeft: -line.indent * INDENT, left: line.indent * INDENT
        @$('.subtree-heading .element-name').html highlightSelector @_getLineName line
      else
        $(@itemsEl).css marginLeft: 0, left: 0
      @$('.subtree-heading').toggleClass 'is-visible', @subtree?
      @setDirty()
      @scrollTo 0

    clearSubtree: -> @selectSubtree()

    getIndex: (id) ->
      return i for line, i in @lines when line.id == id
      -1

    createPseudoInfo: (line) ->
      unless line.pseudoEl
        $(line.el).find('.selector').before line.pseudoEl = node 'span', class: 'pseudos'
      $(line.pseudoEl).empty()
      return unless line.pseudos
      for pseudoClass in line.pseudos when pseudoClass
        $(line.pseudoEl).append el = node 'span', class: 'pseudo-indicator ' + pseudoClass
        $(el).bind 'click', _.bind @clearPseudo, @, line.id, pseudoClass

    clearPseudo: (id, dataClass, e) ->
      app.console.setPseudoValue id, dataClass, false
      e.stopPropagation()
      e.preventDefault()

    setPseudoValue: (lineno, pseudo) ->
      return if !lineno?
      index = @getIndex lineno
      line = @lines[index]
      line.pseudos = pseudo.get('pseudos')
      @createPseudoInfo line if line.el
      
    foldAt: (lineno, notrigger = false) ->
      return if !lineno?
      line = @lines[lineno]
      return unless !line.fold && line.count
      line.fold = 1
      @setDirty lineno
      $(line.el).addClass 'is-folded'
      unless notrigger
        @restoreScrollPosition()
        @trigger 'fold', index: lineno, id: line.id

    unfoldAt: (lineno, notrigger = false) ->
      return unless lineno?
      line = @lines[lineno]
      return unless line.fold
      line.fold = 0
      @setDirty lineno
      $(line.el).removeClass 'is-folded'
      unless notrigger
        @restoreScrollPosition()
        @trigger 'unfold', index: lineno, id: line.id, wasauto: !!line.autofold

    getIndexAt: (offset) ->
     @_updateOffsets() if @offsetDirty
     @offsets[offset]

    getOffset: (index) ->
      @_updateOffsets() if @offsetDirty
      @lines[index].offset

    scrollToIndex: (index) ->
      offset = @getOffset index
      diff = (offset - @scrollOffset) * LINE_HEIGHT - @edge
      if diff < 0
        @scrollerEl.scrollTop = offset * LINE_HEIGHT
      height = @containerHeight - LINE_HEIGHT * if @subtree then 2 else 1
      if diff > height
        @scrollerEl.scrollTop = offset * LINE_HEIGHT - height

    storeScrollPosition: ->
      @scrollPosition = null
      if @selectedIndex != -1 && @selectedIndex != null
        offset = @getOffset @selectedIndex
        diff = offset * LINE_HEIGHT - @scrollOffset * LINE_HEIGHT - @edge
        if diff >= 0 && diff <= @containerHeight - LINE_HEIGHT
          @scrollPosition = offset: diff, selection: true
      unless @scrollPosition
        @scrollPosition = offset: (@scrollOffset || @scrollerEl.scrollTop), selection: false
      @saveScrollPosition()

    saveScrollPosition: ->
      app.console?.state?.save scrollPos: @scrollPosition

    restoreScrollPosition: ->
      @complete = 1
      if @scrollPosition?.selection && @selectedIndex != null
        offset = @getOffset @selectedIndex
        scroll = offset * LINE_HEIGHT - @scrollPosition.offset
      else
        scroll = @scrollPosition?.offset || 0
      @scrollTo scroll, true
      @scrollerEl.scrollTop = scroll
      @storeScrollPosition()

    scrollTo: (offset, noStorePosition = false) ->
      return unless @lines
      @_updateOffsets() if @offsetDirty
      offset = 0 if offset < 0
      maxLines = (Math.ceil @containerHeight / LINE_HEIGHT) + if @subtree? then 0 else 1
      totalLines = @offsets.length
      maxOffset = totalLines - maxLines + 1
      maxOffset = 0 if maxOffset < 0

      oy = Math.floor offset / LINE_HEIGHT
      @edge = offset % LINE_HEIGHT
      offset = if oy > maxOffset then maxOffset else oy
      end = if offset + maxLines < totalLines then offset + maxLines else totalLines
      
      @repaintIndex = !@repaintIndex;
            
      rows = for itemOffset in [offset...end]
        index = @getIndexAt itemOffset
        line = @lines[index]
        #continue unless line
        unless line?.el
          line.text = '| ' + line.text if !line.name && line.text
          el = $ node 'div', class: 'outline-item', style: paddingLeft: line.indent * INDENT + 'px'
          if line.count
            el.append node 'span', class: 'fold-btn'
            el.append node 'div', class: 'select-subtree-btn'
          else
            el.append node 'span', class: 'fold-btn-blank'
          el.append node 'span', class: 'selector', (highlightSelector line.name) if line.name
          el.append node 'span', class: 'text', (line.text) if line.text
          el.addClass 'is-folded' if line.fold
          el.addClass 'is-selected' if index == @selectedIndex
          line.el = el
          @createPseudoInfo line if line.pseudos
          
        line.el.toggleClass 'is-highlighted', @highlightedItems and index in @highlightedItems
        el = line.el.get(0)
        el._lastRepaintIndex = @repaintIndex
        el
      
      # Hiding for single reflow
      $(@itemsEl).hide().css top: offset * LINE_HEIGHT
      if @_doCleanDOM == true
        $(@itemsEl).empty()
        @_doCleanDOM = false
        
      # Switching elements without removing nodes that don't change.
      lastElement = null
      for row in rows
        if row.parentNode != @itemsEl
          if lastElement
            if lastElement.nextSibling
              @itemsEl.insertBefore row, lastElement.nextSibling
            else
              @itemsEl.appendChild row
          else
            if @itemsEl.firstChild
              @itemsEl.insertBefore row, @itemsEl.firstChild
            else
              @itemsEl.appendChild row
        lastElement = row
      
      el = @itemsEl.firstChild
      while el
        next = el.nextSibling
        if el._lastRepaintIndex != @repaintIndex
          @itemsEl.removeChild el
          el._lastRepaintIndex = null
        el = next
        
      $(@scrollerContentsEl).css height: @offsets.length * LINE_HEIGHT
      $(@itemsEl).show()
      @scrollOffset = offset
      @storeScrollPosition() unless noStorePosition

    setTreeData: (data) ->
      @containerHeight = @el.offsetHeight
      @selectedIndex = null
      @lines = []
      @_parseData data
      @setDirty()
      @foldAt i, true for line, i in @lines when line.autofold 
      @_doCleanDOM = true
      if data.length
        @trigger 'load'
      else
        @scrollTo 0
      

  module.exports = TreeOutline
