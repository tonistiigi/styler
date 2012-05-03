define (require, exports, module) ->
  {node} = require 'lib/utils'
  
  TABS_SPACING = 5

  TabView = Backbone.View.extend
    className: 'tab'
    events:
      'click .close-btn': 'onCloseClick'
      'mousedown': 'onMouseDown'

    initialize: ->
      _.bindAll @, 'onMouseMove', 'onMouseUp'

      @$el.append [
        @name = node 'div'
        node 'div', class: 'close-btn'
      ]
      @model.on 'destroy', @onRemove, @
      @model.on 'change:selected', @onSelectedChange, @
      @model.on 'change:highlight', @onHighlightChange, @
      @model.on 'change:error', @renderError, @
      @model.on 'change:saved', @render, @
      @model._view = @ #todo:hacky
      
      _.delay => 
        @$el.addClass 'is-loaded'
      , 1000

    onCloseClick: (e) ->
      @model.tryClose()

    onRemove: ->
      @$el.remove()
      $(@errorEl).remove() if @errorEl?.parentNode

    setOffset: (offset) ->
      @model.set offset: offset
      @$el.css left: offset

    select: ->
      return unless @model.collection
      @model.select()

    renderError: ->
      error = @model.get 'error'
      isSelected = @model.get 'selected'
      if error and isSelected
        @errorEl ?= node 'div', class: 'editor-error'
        @errorEl.innerHTML = "#{error.name} at line #{error.line}: #{error.message}"
        @$el.parent().append @errorEl unless @errorEl.parentNode?.parentNode == @el
      else if @errorEl?.parentNode
        $(@errorEl).remove()

    onSelectedChange: ->
      @$el.toggleClass 'is-selected', @model.get 'selected'
      @renderError()

    onHighlightChange: ->
      @$el.toggleClass 'is-highlight', @model.hlmarkers?.length

    render: ->
      @name.innerHTML = @model.get 'name'
      @name.innerHTML += '*' unless @model.get 'saved'
      @

    getWidth: -> @width = @el.offsetWidth

    onMouseDown: (e) ->
      return if e.button == 2 || $(e.target).hasClass('close-btn')
      @select()
      @isDragging = true
      @_dragManager.startDrag @model if @_dragManager
      @startPosition = e.clientX
      $(window).on('mousemove', @onMouseMove).on('mouseup', @onMouseUp)

    onMouseMove: (e) ->
      return unless @isDragging
      @_dragManager.moveDrag e.clientX - @startPosition

    onMouseUp: (e) ->
      return unless @isDragging
      @isDragging = false
      @_dragManager.endDrag()
      $(window).off('mousemove', @onMouseMove).off('mouseup', @onMouseUp)


  TabListView = Backbone.View.extend

    initialize: ->
      @collection.on 'add', @onAddTab, @
      @collection.on 'reset', @onAddAllTabs, @
      @collection.on 'remove', @onTabRemoved, @

    onAddTab: (tab) ->
      t = new TabView model: tab
      t._dragManager = @
      @$el.append t.render().el
      @positionTabs()
      @saveOrder()
      
    onAddAllTabs: (tabs) -> tabs.each _.bind @addOne, @

    onTabRemoved: -> @positionTabs()

    saveOrder: ->
      @collection.each (t) ->
        offset = t.get 'offset'
        file = t.get 'file'
        fileoffset = file.get 'offset'
        if fileoffset != offset
          file.save offset: offset

    positionTabs: ->
      offset = 0
      @collection.each (t) =>
        t._view.setOffset offset unless t == @draggedTab
        offset += t._view.getWidth() + TABS_SPACING

    startDrag: (tab) ->
      @draggedTab = tab
      @startPosition = tab._view.el.offsetLeft
      $(tab._view.el).addClass 'is-dragging'

    moveDrag: (delta) ->
      pos = @startPosition + delta
      pos = -1 if pos < -1
      maxPos = @el.offsetWidth - @draggedTab._view.getWidth()
      pos = maxPos if pos > maxPos
      @draggedTab._view.setOffset pos
      @collection.sort silent: true
      @positionTabs()

    endDrag: ->
      $(@draggedTab._view.el).removeClass 'is-dragging'
      @draggedTab = null
      @positionTabs()
      @saveOrder()

  TabView: TabView
  TabListView: TabListView
