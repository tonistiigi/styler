define (require, exports, module) ->

  require 'vendor/link!css/commandline.css'
  
  keys = require 'ace/lib/keys'
  {node} = require 'lib/utils'
  {listenKey} = require 'lib/keyboard'
  {stopEvent} = require 'ace/lib/event'

  CommandLine = Backbone.View.extend
    initialize: ->
      _.bindAll @, 'activate', 'close', 'onChange', 'onKeyUp', 'onKeyDown'

      @active = false
      @value = ''

      listenKey null, 'toggle-cli', exec: => if @active then @close() else @activate()

      @$el.append [
        @input = node 'input', type: 'text'
        @options = node 'div', class: 'options'
      ]

      $(@input).on 'blur', => @close() if @active

    activate: ->
      @$el.addClass 'is-open'
      @active = true
      @setItems []
      @selectedValue = null
      @selectedIndex = -1

      $(@input).focus().val('')
        .on('keydown', @onKeyDown)
        .on('keyup', @onKeyUp)
        .on('change', @onChange)
        
    close: ->
      @$el.removeClass 'is-open'
      @active = false
      
      $(@input).blur().val('')
        .off('keyup', @onKeyUp)
        .off('keydown', @onKeyDown)
        .off('change', @onChange)

    setItems: (@items) ->
      @selectedIndex = -1
      fragment = document.createDocumentFragment()

      for item, i in items
        return unless items
        item.el =
          if item.file
            node 'div', class: 'item',
              node 'div', class: 'value',
                'open file '
                node 'span', (item.value)
              node 'div', class: 'hint', (item.hint)
          else if item.selector
            node 'div', class: 'item',
              node 'div', class: 'value',
                'open element '
                node 'span', (item.value)
        item.index = i

      fragment.appendChild item.el for item in items.reverse()
      items.reverse()

      if item = _.find(items, (item) -> item.value == @selectedValue)
        @selectIndex item.index
      else
        @selectIndex if items.length then 0 else -1

      $(@options).toggle(!!items.length).empty().append fragment

    selectIndex: (index) ->
      return if index == @selectedIndex || !@items.length
      $(@items[@selectedIndex].el).removeClass 'selected' if @selectedIndex != -1
      @selectedIndex = index
      @selectedValue = @items[index].value
      $(@items[@selectedIndex].el).addClass 'selected' if @selectedIndex != -1

    onKeyDown: (e) ->
      switch keys[e.keyCode]
        when 'Down'
          @selectIndex @selectedIndex - 1 if @selectedIndex > 0
          stopEvent e
          return
        when 'Up'
          @selectIndex @selectedIndex + 1 if @selectedIndex < @items.length - 1
          stopEvent e
          return
        when 'Return'
          if @active
            item = @items?[@selectedIndex]
            app.console.openFile item.file.get 'url' if item.file
            app.console.onFocusedSelectorChange item.value, true if item.selector
            @close()
            stopEvent e
        when 'Esc'
          @input.blur() if @active
          stopEvent e

    onKeyUp: (e) ->
      @onChange()

    onChange: ->
      return if @value == @input.value
      @value = @input.value
      return @setItems [] unless @value.length
      @getCompletions @value, (items) => @setItems items

    searchFilesByName: (value) ->
      value = value.toLowerCase()
      app.console.editor.filebrowser.collection.chain()
        .filter((file) -> -1 != file.get('name').toLowerCase().indexOf value)
        .sortBy((file) -> file.get('name').toLowerCase().indexOf value)
        .first(5)
        .map((file) -> value: file.get('name'), file: file, hint: file.get('url'))
        .value()

    getCompletions: (value, cb) ->
      completions = @searchFilesByName value
      selectorParts = value.split /\s+/
      [lastPart] = selectorParts[-1..]
      parentPart = selectorParts[...-1].join ' '
      app.console.callClient 'findElementMatches', selector: lastPart, parent: [parentPart], offset: lastPart.length, after: null, (response) ->
        if response?.results?.length
          _.each response.results, (selector) ->
            completions.push
              value: (if parentPart then parentPart + ' ' else '') + selector
              selector: 1
        cb completions

  module.exports = CommandLine