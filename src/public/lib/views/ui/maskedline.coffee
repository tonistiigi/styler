define (require, exports, module) ->

  # NOTE: This element has very poor performace on Firefox.
  # If no solution is found then it needs to be removed.

  MaskedLine = Backbone.View.extend

    RANGE: .25
    FRICTION: .90
    SPEED: .5
    TOPSPEED: 3

    initialize: ->
      _.bindAll @, "onenterframe", "onmousemove", "onmouseover", "onmouseout"
      $(@el).addClass "maskedline"
      @scrollable = @el.firstChild
      @inner = @scrollable.firstChild
      $(@inner).addClass "inner"
      $(@scrollable).bind "mouseover", @onmouseover
      $(@scrollable).bind "mouseout", @onmouseout
      @xpos = 0
      @vx = 0
      @ax = 0
      @over = false
      @offset = 0

    onenterframe: ->
      return if @outwidth <= @inwidth
      rate = 0
      if @xpos < @inwidth * @RANGE
        rate =  @xpos / (@inwidth * @RANGE) - 1
      else if @xpos > @inwidth - @inwidth * @RANGE
        rate = (@xpos - @inwidth + @inwidth * @RANGE) / (@inwidth * @RANGE)

      @ax = rate * @SPEED
      @vx += @ax 
      @vx *= @FRICTION
      @vx = @TOPSPEED if @vx > @TOPSPEED
      @vx = -@TOPSPEED if @vx < -@TOPSPEED
      @vx = 0 if @vx > 0 and @vx < 0.01
      @vx = 0 if @vx < 0 and @vx > -0.01

      @offset = @inner.offsetLeft
      @offset -= @vx
      if @offset > 0
        @offset = 0
        @vx = 0
      else if @offset < @inwidth - @outwidth
        @offset = @inwidth - @outwidth
        @vx = 0
      @inner.style.left = @offset+"px"
      #console.log @inwidth, @outwidth, @xpos, rate, @vx, @offset

    onmousemove: (e) ->
      @xpos = (e.offsetX || e.layerX)+@offset

    onmouseover: (e) ->
      return if @over
      @outwidth = @inner.scrollWidth
      @inwidth = @scrollable.offsetWidth
      @xpos = e.clientX-e.currentTarget.offsetLeft
      $(@scrollable).bind "mousemove", @onmousemove
      @interval = setInterval @onenterframe, 35
      $(@el).addClass "overstate"
      $(@el).removeClass "outstate"
      
      @over = true

    onmouseout: (e) ->
      dx = (e.offsetX || e.layerX)
      dy = (e.offsetY || e.layerY)
      return if dx+@offset > 0 && dx+@offset < @inwidth-3 && dy > 0 && dy < 15
      @reset()
      
    reset: ->
      $(@scrollable).unbind "mousemove", @onmousemove
      clearInterval @interval
      $(@el).removeClass "overstate"
      $(@el).addClass "outstate"
      _.delay => @inner.style['left'] = "0px"
      @vx = 0
      @over = false

  module.exports = MaskedLine