define (require, exports, module) ->

  {node} = require 'lib/utils'

  require 'vendor/link!css/imagepreview.css'

  EDGE = 140

  ImagePreview = Backbone.View.extend

    className: 'overlay'

    events:
      'click' : 'dismissOnOverlay'

    initialize: (url) ->
      _.bindAll @, 'onKeyDown'
      ImagePreview.getPreviewElement url, window.innerWidth - EDGE, window.innerHeight - EDGE, (err, element) =>
        if err
          @dismiss()
        else
          @el.appendChild element

      document.addEventListener 'keydown', @onKeyDown, true
      $(document.body).append @el
      _.delay =>
        @$el.addClass 'is-loaded'
      , 30

    dismissOnOverlay: (e) ->
      @dismiss()

    dismiss: ->
      document.removeEventListener 'keydown', @onKeyDown, true
      @$el.removeClass 'is-loaded'
      _.delay (=> @$el.remove()), 500

    onKeyDown: (e) ->
      switch e.keyCode
        when 27 # Esc.
          @dismiss()

      e.stopPropagation()
      e.preventDefault()

  ImagePreview.getPreviewElement = (url, maxWidth, maxHeight, cb) ->
    img = $(node 'img', src: url)
    img.on 'load', ->
      {naturalWidth: width, naturalHeight: height} = img[0]
      return cb true unless width && height

      scale = Math.min maxWidth / width, maxHeight / height
      scale = 1 if scale > 1

      cb null, node 'div', class: 'imagepreview',
        node 'div', class: 'image', style: width: (Math.floor width * scale), height: (Math.floor height * scale),
          node 'div', class: 'inner', style: backgroundImage: "url(#{url})"
        node 'div', class: 'imginfo',
          node 'div', class: 'name', (url.split('/')[-1..][0])
          node 'div', class: 'size', "#{width} x #{height}"

    img.on 'error', ->
      console.log 'error'
      cb true

  module.exports = ImagePreview