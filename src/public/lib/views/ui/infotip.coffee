define (require, exports, module) ->

  {node} = require "lib/utils"

  require "vendor/link!css/infotip.css"

  InfoTip = Backbone.View.extend

    className: "infotip"
      
    events:
      'mousemove': 'onMouse'
      'mousedown': 'onMouse'

    initialize: ->
      _.bindAll @, 'onTargetMouseMove', 'onTargetMouseOut', 'onMouse'

      @count = 0
      @hide()

    onMouse: (e) ->
      @hide() if @visible

    onTargetMouseMove: (e) ->
      @pos.x = event.pageX
      @pos.y = event.pageY
      @renderPosition() if @visible

    onTargetMouseOut: (e) ->
      @hide()

    renderPosition: ->
      left = @pos.x - @pos.width / 2
      top =  @pos.y + 15
      
      rightEdge = left + @pos.width + 30 - window.innerWidth
      left -= rightEdge if rightEdge > 0
      if top + @pos.height + 30 > window.innerHeight
        top -= 30 + @pos.height
      
      @$el.css left: left, top: top
      
    showPanel: (event, width, height, contents, target) ->
      @hide() if @visible
      @count++
      @target = target || event.target

      @pos = x: event.pageX, y: event.pageY, width: width, height: height

      $(@target).on 'mousemove', @onTargetMouseMove
      $(@target).on 'mouseout', @onTargetMouseOut
      
      @visible = true
      
      do _.bind (count) =>
        return unless count == @count
        contents (el) =>
          return unless @visible
          @$el.empty().append(el).css(width: width, height: height).show()
          @renderPosition()
          document.body.appendChild @el
      , @, @count

    hide: ->
      $(@target).off 'mousemove', @onTargetMouseMove
      $(@target).off 'mouseout', @onTargetMouseOut

      @$el.hide().remove()
      @visible = false

  module.exports = new InfoTip