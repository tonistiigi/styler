define (require, exports, module) ->

  require 'vendor/link!css/styleinfo.css'

  {node, basename, highlightSelector, rgbToHex} = require 'lib/utils'
  {addKeyboardListener,listenKey} = require 'lib/keyboard'

  StyleInfo = Backbone.View.extend

    initialize: ->
      _.bindAll @, 'onItemClick'

      @states = {}
      @currentState = {}

      @$el.append [
        @items = node 'div', class: 'style-items'
        node 'div', class: 'no-items-fallback', 'No element is selected.'
      ]
      addKeyboardListener 'styleinfo', @el

      @el.listenKey 'style-item-down', exec: => @moveHighlight 1
      @el.listenKey 'style-item-up', exec: => @moveHighlight -1
      @el.listenKey 'style-item-expand', exec: => @expand true
      @el.listenKey 'style-item-collapse', exec: => @expand false
      @el.listenKey 'style-item-open', exec: => @open()
      @el.listenKey 'switch-back-to-outline', exec: => @trigger 'focus:outline'
      @el.listenKey 'style-selector-up', exec: => @moveHighlight -1, true
      @el.listenKey 'style-selector-down', exec: => @moveHighlight 1, true

      for i in [1..9]
        listenKey null, "open-style-#{i}", mac: "Command-Alt-#{i}", win: "Ctrl-Shift-#{i}", exec: _.bind @openStyleAtIndex, @, i - 1

    openStyleAtIndex: (i) ->
      return unless el = $(@$('.file').get(i)).next()[0]
      @highlight el
      @open()

    moveHighlight: (delta, selectorOnly = false) ->
      opt = @$('.name' + if selectorOnly then '' else ',.style-prop:first-child,.style-prop-container.is-expanded .style-prop-sub')
      @highlightElement = opt[0] unless @highlightElement
      index = opt.indexOf @highlightElement
      index = 0 unless index != -1
      index += delta
      index = 0 if index >= opt.length
      index = opt.length - 1 if index < 0
      @highlight opt[index]
      if event
        event.stopPropagation()
        event.preventDefault()

    expand: (expand) ->
      return unless @highlightElement and $(@highlightElement).hasClass 'propitem'
      $(@highlightElement.parentNode).toggleClass 'expanded', expand

    openImage: (urlvalue) ->
      url = (urlvalue.match /^url\(['"]?(.*)["']?\)$/i)[1]
      @infoTip?.hide()
      require ['lib/views/ui/imagepreview'], (ImagePreview) ->
        new ImagePreview url

    showImageInfo: (urlvalue, e) ->
      url = (urlvalue.match /^url\(['"]?(.*)["']?\)$/i)[1]
      require ['lib/views/ui/infotip', 'lib/views/ui/imagepreview'], (infoTip, ImagePreview) =>
        @infoTip = infoTip
        infoTip.showPanel e, 130, 100, (cb) ->
          ImagePreview.getPreviewElement url, 120, 70, (err, el) ->
            return if err
            cb el

    createValueElement: (value) ->
      fragment = node 'span', class: 'style-prop-value'
      i = 0

      value.replace /#[a-f\d]{3,6}|rgba?\([\d,\.\s]{5,}\)|url\([\w'":\/\.\?_@-]{5,}\)|'.*?'|".*?"|-?[\d\.]+(?:px|em|ex|cm|mm|in|pt|pc|deg|rad|grad|ms|s|hz|khz|\%)(?:\b|;)/gi, (match, offset) =>
        fragment.appendChild node 'span', (value.substring i, offset) if i < offset
        valuePart = value.substr offset, match.length
        if match[..2].toLowerCase() == 'url'
          fragment.appendChild spanurl = node 'span', class: 'url', valuePart
          $(spanurl)
            .on('click', _.bind @openImage, @, valuePart)
            .on('mouseover', _.bind @showImageInfo, @, valuePart)
        else if match[0] in ['"', "'"]
          fragment.appendChild node 'span', class: 'quoted', valuePart
        else if num = match.match /^[\d-\.]+/
          fragment.appendChild node 'span', class: 'numeric',
            node 'span', class: 'value', (value.substr offset, num[0].length)
            (value.substr offset + num[0].length, match.length - num[0].length)
        else
          fragment.appendChild node 'span', class: 'color-sample', style: (background: match)
          fragment.appendChild node 'span', class: 'color-name', (rgbToHex valuePart)
        i = offset + match.length
      fragment.appendChild node 'span', (value.substring i, value.length) if i < value.length
      fragment

    focusSelector: (sel, force=false) ->
      return if sel == @lastFocus && !force
      @$('.name').each (i, el) =>
        $el = $ el
        @highlight el if $el.attr('data-selector') == sel && !$el.closest('.style-item').hasClass 'is-focused'
      @lastFocus = sel

    _onInheritedElementClick: (id) ->
      app.console?.outline.select id

    getFilename: (url) ->
      sources = app.console.project.get 'files'
      source = _.find sources, (source) -> 0 == url.indexOf source.url
      name = basename url
      if source?.type == 'stylus'
        name = name.replace /\.css$/i, '.styl'
      name

    setStyleData: (id = 0, data = [], nearby = [], elinfo = null) ->
      @$el.toggleClass 'has-items', !!data.length

      @highlightElement = null
      $(@items).empty()
      fragment = document.createDocumentFragment()
      if elinfo != null
        serialize = [elinfo.index, elinfo.length, elinfo.selector].join '_'
        @states[serialize] ?= {}
        @currentState = @states[serialize]
      else
        @currentState = null

      lastInheritedElement = null

      for sdata in data
        item = node 'div', class: 'style-item'
        if sdata.type == 'inherited' && sdata.element.id + sdata.element.name != lastInheritedElement
          item.appendChild node 'div', class: 'inherit', 'Inherited from' ,
            elname = node 'span', class: 'element-name', (highlightSelector sdata.element.name)
          if sdata.element.id
            $(elname).addClass('is-selectable').bind('click', _.bind @_onInheritedElementClick, @, sdata.element.id)
          lastInheritedElement = sdata.element.id+sdata.element.name
        if sdata.file
          fileitem = item.appendChild node 'div', class: 'file', (@getFilename sdata.file)
          $(fileitem).bind 'click', _.bind @onFileClick, @, sdata.file, sdata.selector, sdata.index
        item.appendChild name = node 'div', class: 'name', 'data-selector': sdata.selector, if sdata.type == 'element' then 'element.style' else highlightSelector sdata.selector
        $(name).bind 'click', @onItemClick
        if sdata.file
          $(name).bind 'dblclick', _.bind @onFileClick, @, sdata.file, sdata.selector, sdata.index
        if sdata.media
          item.appendChild node 'div', class: 'media',
            node 'span', class: 'label', '@media'
            node 'span', class: 'value', (sdata.media)

        item.sdata = sdata
        item.appendChild properties = node 'div', class: 'properties'

        numStyles = 0
        for name, value of sdata.styles
          numStyles++
          #todo: combine props and subprops into same routine
          properties.appendChild prop = node 'div', class: 'style-prop-container' + (if value.disabled then ' is-disabled' else ''),
            prop_item = node 'div', class: 'style-prop',
              node 'div', class: 'expand-bullet' + if _.size(value.subStyles) then ' is-visible' else ''
              node 'span', class: 'prop-name', name
              @createValueElement value.value
              if value.priority then node 'span', class: 'priority', ('!' + value.priority) else null
          $(prop_item).bind 'click', @onItemClick
          if @currentState?[sdata.selector+';'+sdata.file]?[name]
            $(prop).addClass 'is-expanded'
          if value.subStyles
            for sname, svalue of value.subStyles
              prop.appendChild subprop = node 'div', class: 'style-prop style-prop-sub' + (if svalue.disabled then ' is-disabled' else ''),
                node 'span', class: 'prop-name', sname
                @createValueElement svalue.value
                if svalue.priority then node 'span', class: 'priority', ('!' + svalue.priority) else null
              $(subprop).bind 'click', @onItemClick
          $(prop).bind 'dblclick', _.bind @onPropDblClick, @, sdata.file, sdata.selector, sdata.index, name
        continue if sdata.type == 'element' && !numStyles
        fragment.appendChild item

      if nearby.length
        nearbyEl = node 'div', class: 'nearby-rules',
          node 'div', class: 'head', 'Nearby rules'
        for rule in nearby
          nearbyEl.appendChild item = node 'div', class: 'item', (highlightSelector rule.selector)
          $(item).bind 'click', _.bind @onFileClick, @, rule.file, rule.selector
        fragment.appendChild nearbyEl

      $(@items).append fragment

      if @lastId==id
        @focusSelector @lastFocus, true
      else
        @lastFocus = null
      @lastId = id

    onPropDblClick: (file, selector, index, property) ->
      @trigger 'open', file, selector, index, property

    onFileClick: (file, selector, index) ->
      @trigger 'open', file, selector, index

    highlight: (el) ->
      $el = $ el
      @$('.is-highlighted').removeClass 'is-highlighted'
      $el.addClass 'is-highlighted'
      @$('.is-focused').removeClass 'is-focused'
      $el.closest('.style-item').addClass 'is-focused'
      @highlightElement = el

      styleItem = $el.closest('.style-item')[0]
      if styleItem.scrollIntoViewIfNeeded
        styleItem.scrollIntoViewIfNeeded()
      else
        if @highlightElement.offsetTop < @el.scrollTop
          @el.scrollTop = @highlightElement.offsetTop
        else if @highlightElement.offsetTop + 20 > @el.offsetHeight + @el.scrollTop
          @el.scrollTop = @highlightElement.offsetTop + 20 - @el.offsetHeight

    open: ->
      return unless @highlightElement
      el = $(@highlightElement)
      if el.hasClass('style-prop-container') || el.hasClass('style-prop-sub')
        prop = el.find('.name').text()
        styleitem = el.closest('.style-item')[0]
        sdata = styleitem.sdata
        if sdata.file
          @trigger 'open', sdata.file, sdata.selector, sdata.index, prop
      if el.hasClass 'name'
        sdata = el.closest('.style-item')[0].sdata
        @trigger 'open', sdata.file, sdata.selector, sdata.index if sdata.file

    onItemClick: (e) ->
      prop = $(e.currentTarget)
      if prop.hasClass('name') or prop.hasClass('style-prop')
        @highlight prop[0]
      if e.detail == 2 or $(e.target).hasClass('expand-bullet')
        expand = !prop.parent().hasClass 'is-expanded'
        prop.parent().toggleClass 'is-expanded', expand
        if @currentState
          sdata = prop.closest('.style-item')[0].sdata
          state = @currentState[sdata.selector + ';' + sdata.file] ?= {}
          propname = prop.find('.prop-name').text()
          if expand
            state[propname] = 1
          else
            delete state[propname]

  module.exports = StyleInfo