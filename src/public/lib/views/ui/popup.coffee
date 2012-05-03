define (require, exports, module) ->
  
  keys = require 'ace/lib/keys'
  {node} = require 'lib/utils'
  
  require 'vendor/link!css/popup.css'
  
  ## This popup is used for unsaved file dialogs.

  Popup = Backbone.View.extend

    className: 'overlay'

    events:
      'click' : 'dismissOnOverlay'

    initialize: (conf) ->
      _.bindAll @, 'onKeyDown'

      @el.appendChild node 'div', class: 'popup',
        node 'div', class: 'msg', (conf.msg)
        buttons = node 'div', class: 'buttons'

      for button, i in conf.buttons
        btn = node 'div', class: 'button ' + button.id, tabIndex: i,  (button.txt)
        $(btn).on 'click', _.bind (button) ->
          button.exec()
          @dismiss()
        , @, button
        buttons.appendChild btn
        @buttonIndex = i if button.highlight

      document.addEventListener 'keydown', @onKeyDown, true
      $(document.body).append @el
      _.delay =>
        @$el.addClass 'is-loaded'
        @focusButton()
      , 30

    dismissOnOverlay: (e) ->
      @dismiss() if e.target == @el

    dismiss: ->
      document.removeEventListener 'keydown', @onKeyDown, true
      @$el.removeClass 'is-loaded'
      _.delay =>
        @$el.remove()
      , 500

    focusButton: (delta = 0) ->
      return unless @buttonIndex?
      @buttonIndex += delta
      numButtons = @$('.button').size()
      @buttonIndex = numButtons - 1 if @buttonIndex < 0
      @buttonIndex = 0 if @buttonIndex >= numButtons
      @$('.button').get(@buttonIndex).focus()

    selectButton: (index) ->
      return unless button = @$('.button').get(index)
      button.onclick?()

    onKeyDown: (e) ->
      switch keys[e.keyCode]
        when 'Esc'
          @dismiss()
        when 'Tab'
          @focusButton if e.shiftKey then -1 else 1
        when 'Space', 'Return'
          @selectButton @buttonIndex
        when 'Left'
          @focusButton -1
        when 'Right'
          @focusButton 1

      e.stopPropagation()
      e.preventDefault()

  module.exports = Popup