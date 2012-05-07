define (require, exports, module) ->

  {stopEvent} = require 'ace/lib/event'
  ua = require 'ace/lib/useragent'
  keys = require 'ace/lib/keys'
  {node, style} = require 'lib/utils'
  
  require 'vendor/link!css/completer.css'
  
  Completer = Backbone.View.extend
    className: 'completer'

    initialize: ->
      _.bindAll @, 'onKeyDown', 'onMouseWheel', 'onMouseDown'
      @$el.append @previewElement = node 'div', class: 'preview'
      @$el.append @itemsElement = node 'div', class: 'items'  
      $(@itemsElement).on 'mousedown', @onMouseDown
      @reverse = false
      @disable true

    activate: (@tab, completions, row, col) ->
      items = completions.items
      return @disable() unless items?.length
      
      # TODO: Cleanup needed for the offsets. Too messy and doesn't have the benefits of the original plan.
      items = _.uniq items, false, (i) -> i.value
      @offset = if items[0].offset? then items[0].offset else completions.offset
      items = items.slice 0, 100 if items.length > 100
      
      {editor} = @tab.get 'editor'
      editorPos = editor.container.getBoundingClientRect()
      pxcoord = editor.renderer.textToScreenCoordinates row, col - @offset
      top = (pxcoord.pageY - editorPos.top)
      @reverse = editorPos.height - top < 140

      @$el.toggleClass('is-reverse', @reverse).css if @reverse
          left: pxcoord.pageX - editorPos.left - 2 
          top: 'auto'
          bottom: editorPos.height - top
        else
          left: pxcoord.pageX - editorPos.left - 2
          top: top + editor.renderer.lineHeight
          bottom: 'auto'

      unless @active
        @$el.show()
        window.addEventListener 'keydown', @onKeyDown, true
        window.addEventListener 'mousewheel', @onMouseWheel, true

      @active = true
      @keyDelta = 0
      items = items.reverse() if @reverse
      @setItems items, @offset

    disable: (force = false)->
      if @active || force
        @$el.hide()
        @active = false
        @selectedValue = ''
        window.removeEventListener 'keydown', @onKeyDown, true
        window.removeEventListener 'mousewheel', @onMouseWheel, true

    setItems: (items) ->
      $(@itemsElement).empty()
      @selectedIndex = -1
      @items = []
      fragment = document.createDocumentFragment()
      @items = for item, i in items
        offset = if item.offset? then item.offset else @offset
        el = node 'div', class: 'item',
          node 'span', class: 'general', (item.value.substr 0, offset)
          node 'span', class: 'unique', (item.value.substr offset)
        if item.color
          $(el).addClass('color').css 'border-color': item.value
        _.extend item,
          el: el
          i: i
          isSame: item.value.length <= offset
        fragment.appendChild el
        item
      return @disable() if @items.length == 1 and @items[0].isSame

      $(@itemsElement).append fragment
      {editor} = @tab.get 'editor'
      @$el.css height: editor.renderer.lineHeight * Math.min items.length, 6
      item = _.find items, (i) -> i.value == @selectedValue
      @select if item then item.i else if @reverse then items.length - 1 else 0
      @disable() unless @items.length
      
    onMouseDown: (e) ->
      itemEl = $(e.target).closest('.item')[0]
      [item] = (item for item in @items when item.el == itemEl)
      @completeItem item if item

    select: (index) ->
      return if index == @selectedIndex
      if @selectedIndex != -1
        item = @items[@selectedIndex]
        $(item.el).removeClass 'selected'
      @selectedIndex = index
      if item = @items[@selectedIndex]
        $(item.el).addClass 'selected'
        @selectedValue = item.value
        if item.preview
          @showPreview item
        else if @isPreview
          @hidePreview()
        
        if item.el.scrollIntoViewIfNeeded
          item.el.scrollIntoViewIfNeeded false
        else
          item.el.scrollIntoView? false

    completeItem: (item) ->
      if item
        item.offset ?= @offset
        @tab.complete item
        @disable()
    
    showPreview: (item) ->
      @isPreview = true
      url = item.preview.split('/')[...-1].join('/') + '/' + item.value
      require ['lib/views/ui/imagepreview'], (ImagePreview) =>
        ImagePreview.getPreviewElement url, 120, 75, (err, el) =>
          return if err
          $(@previewElement).empty().append(el).show() if @isPreview
      
    hidePreview: ->
      @isPreview = false
      $(@previewElement).hide().empty()
    
    onMouseWheel: ->
      @disable()
    
    moveSelection: (delta, e) ->
      directionDown = delta > 0
      keyDelta = if directionDown then -1 else 1
      if (if directionDown then @selectedIndex < @items.length - 1 else @selectedIndex > 0)
        @select Math.max 0, (Math.min @selectedIndex + delta, @items.length - 1)
      else if @keyDelta != keyDelta
        @keyDelta = keyDelta
      else
        @disable()
      stopEvent e
        
    onKeyDown: (e) ->
      return if e.shiftKey

      switch keys[e.keyCode]
        when 'Down'
          @moveSelection 1, e
        when 'Up'
          @moveSelection -1, e
        when 'PageDown'
          @moveSelection 10, e
        when 'PageUp'
          @moveSelection -10, e
        when 'End'
          @moveSelection 1e3, e
        when 'Home'
          @moveSelection -1e3, e

        when 'Return'
          if item = @items[@selectedIndex]
            stopEvent e
            if ua.isMozilla && item.exec
              _.defer => @completeItem item
            else
              @completeItem item
            
        when 'Esc'
          @disable()
          stopEvent e

        when 'Tab'
          if item = @items[@selectedIndex]
            if @items.length == 1
              @completeItem item
            else
              # Cycle through all items until there is a common part
              offset = offset_ = if item.offset then item.offset else @offset
              while true
                offset_++
                part = @items[@selectedIndex].value.substr 0, offset_
                matches = true
                for i in @items
                  if i.length < offset or part != i.value.substr 0, offset_
                    matches = false
                    break
                if !matches
                  break
              offset_--
              if offset_ > offset
                @tab.complete value: (@items[@selectedIndex].value.substr 0, offset_), offset: offset
          stopEvent e 

  module.exports = Completer