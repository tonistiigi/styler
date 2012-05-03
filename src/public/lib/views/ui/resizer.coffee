define (require, exports, module) ->

  require 'vendor/link!css/resizer.css'

  {getStyle} = require 'lib/utils'

  Resizer = Backbone.View.extend

    events:
      'mousedown' : 'onMouseDown'

    initialize: (opt) ->
      _.bindAll @, 'onMouseMove', 'onMouseUp', 'onDOMLoaded', 'onSelection'

      @target = $(opt.target)
      if @name = opt.name
        @STORE_KEY_PROP = "_resizer_#{@name}_prop"
        @STORE_KEY = "_resizer_#{@name}"
        @setFlexValue opt.target, sessionStorage.getItem(@STORE_KEY_PROP), sessionStorage.getItem(@STORE_KEY)
      _.delay @onDOMLoaded, 100

    setFlexValue: (el, prop, value) ->
      return unless prop
      value = @min if value < @min
      value = max if @max && value > @max
      $(el).css prop, parseInt value
      if @name
        sessionStorage.setItem @STORE_KEY, value
        sessionStorage.setItem @STORE_KEY_PROP, prop

    onDOMLoaded: ->
      parent = @$el.parent()
      @orient = parent.css('-webkit-box-orient') || parent.css('-moz-box-orient')
      # TODO: Layout has changed. Check if this min value detection is needed.
      @prop = if @orient == 'horizontal' then 'width' else 'height'
      @min = parseInt (@target.css 'min-' + @prop), 10
      @max = parseInt (@target.css 'max-' + @prop), 10

    # Prevent selecting elements on mouse movement.
    onSelection: (e) ->
      e.stopPropagation()
      e.preventDefault()

    onMouseDown: (e) ->
      $(window).on('mousemove', @onMouseMove).bind('mouseup', @onMouseUp)
      $(document).on 'selectstart', @onSelection
      
      sidebar_right = app.Settings.get 'sidebar_right'
      @startPosition = if @orient == 'horizontal' then e.clientX * (if sidebar_right then -1 else 1) else e.clientY
      @startValue = parseInt (@target.css @prop), 10
      @target.addClass 'is-resizing'
      e.stopPropagation()
      e.preventDefault()

    onMouseMove: (e) ->
      sidebar_right = app.Settings.get 'sidebar_right'
      currentPosition = if @orient == 'horizontal' then e.clientX * (if sidebar_right then -1 else 1) else e.clientY
      value = @startValue  + currentPosition - @startPosition
      @setFlexValue @target, @prop, value
      @trigger 'resize'
      e.stopPropagation()
      e.preventDefault()

    onMouseUp: ->
      $(window).off('mousemove', @onMouseMove).off('mouseup', @onMouseUp)
      $(document).off 'selectstart', @onSelection
      @target.removeClass 'is-resizing'

  module.exports = Resizer
