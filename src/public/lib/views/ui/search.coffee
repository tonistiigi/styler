define (require, exports, module) ->

  ua = require 'ace/lib/useragent'
  {node} = require 'lib/utils'
  {addKeyboardListener, formatKeyCommand, listenKey} = require 'lib/keyboard'
  
  Search = Backbone.View.extend
    initialize: (opt) ->
      _.bindAll @, 'onBlur', 'onKeyUp', 'toggleSearch'

      @editor = opt.editor

      @input = node 'input', class: 'keyword'
      $(@input).on('blur', @onBlur).on('keyup', @onKeyUp)
      
      addKeyboardListener 'search', @input
      
      listenKey null, 'search-in-file', exec: @toggleSearch
      listenKey null, 'search-next-result', exec: => @moveRange false
      listenKey null, 'search-previous-result', exec: => @moveRange true
      @input.listenKey 'disable', mac: 'esc|return', exec: => @disable()
      
      key = app.Settings.get('keyboard_shortcuts')['search-next-result']
      key = if ua.isMac then key.mac else key.win
      
      @$el.append @input
      @$el.append node 'div', class: 'results',
        node 'div', class: 'msg'
        node 'div', class: 'hint', (formatKeyCommand(key) + ' for next')
          
    toggleSearch: ->
      if @active then @disable() else @activate()

    moveRange: (moveup = false) ->
      if @ranges?.length
        if moveup
          @selectedRange -= 1
        else
          @selectedRange += 1

        if @selectedRange < 0
          @selectedRange = @ranges.length - 1
        if @selectedRange >= @ranges.length
          @selectedRange = 0

        @editor.editor.selection.setSelectionRange @ranges[@selectedRange]
        @$('.results .msg').html "Showing <span>#{@selectedRange + 1}</span> of <span>#{@ranges.length}</span>"
      else
        @$('.results .msg').html 'No results found'

      @$('.results').show()


    onKeyUp: ->
      if @input.value != @value
        @value = @input.value
        @editor.editor.$search.set needle: @value
        @ranges = @editor.editor.$search.findAll @editor.editor.session
        @selectedRange = -1
        @moveRange()

    onBlur: ->
      @disable()

    activate: ->  
      @$el.show()
      $(@input).focus()[0].select()

    disable: ->
      @$el.hide()
      @$('.results').hide()
      @editor.editor.focus()

  module.exports = Search
