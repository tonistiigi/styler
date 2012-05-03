define (require, exports, module) ->
  {node, style, getStyle} = require 'lib/utils'
  ua = require 'ace/lib/useragent'

  URLInput = Backbone.Model.extend
    defaults:
      url: ''
      path: ''
      type: 'css'
      newfiles: true
      stylusout: ''

  URLInputList = Backbone.Collection.extend
    model: URLInput

  URLInputView = Backbone.View.extend
    tagName: 'form'

    className: 'item'

    template: require 'lib/templates/url_input'

    events:
      'click .btn.remove': 'onRemoveClick'
      'click .btn.browse-source': 'onBrowseClick'
      'click .btn.browse-stylus-out': 'onBrowseStylusOutClick'
      'click .btn.edit': 'onEditClick'
      'click .btn.convert': 'onConvertClick'

      'change input.url': 'onURLChange'
      'change input.path': 'onPathChange'

      'change input.type': 'onTypeChange'
      'change input.missing-files': 'onMissingFilesChange'
      'change input.stylus-out': 'onStylusOutChange'

    initialize: ->
      _.bindAll @, 'onURLFocus', 'onURLBlur', 'startDirectoryComplete', 'onDirectoryKeyDown', 'onDirectoryKeyUp', 'endDirectoryComplete', 'onPathChange'

      @model.bind 'remove', @onRemove, @

      $(@el).html @template id: @model.cid

      @$('input.url')
        .on('focus', @onURLFocus)
        .on('blur', @onURLBlur)
      
      @$('input.path')
        .on('focus', @startDirectoryComplete)
        .on('blur', @onPathChange)
      @$('input.stylus-out').on 'focus', @startDirectoryComplete
      
      @_completionCache = {}
      @updateFileList()
      @validate => @render()

    render: ->
      @client = @model.get 'client'
      
      # Value setting from the model.
      @$('.url').val @model.get('url')
      @$('.path').val @fromAbsolute  @model.get 'path' 
      @$('.stylus-out').val @fromAbsolute @model.get 'stylusout'
      @$('.type[value=css]')[0].checked = @model.get('type') == 'css'
      @$('.type[value=stylus]')[0].checked = @model.get('type') == 'stylus'
      @$('.missing-files[value=ignore]')[0].checked = !@model.get 'newfiles'
      @$('.missing-files[value=create]')[0].checked = !!@model.get 'newfiles'

      # URL issues detected locally.
      isNoURLError = @status in ['url_format', 'url_empty']
      @$('.input-row.url').toggleClass 'has-error', isNoURLError
      @$('.locations-info .head-note').toggleClass 'no-url', isNoURLError
      if @status == 'url_empty'
        @$('.input-row.url .note').html 'URL field can\'t be empty.'
      else if @status == 'url_format'
        @$('.input-row.url .note').html 'This URL is in wrong format'

      # List files that are affected.
      fragment = document.createDocumentFragment()
      for filename in @filenames
        fragment.appendChild item = node 'div', class: 'searched-file-item', filename
        status = @scan?.files?[filename]
        $(item).addClass (if status then 'found' else 'missing') if status?
      @$('.file-list').empty().append fragment

      # File list heading
      noFilesFound = !isNoURLError && !@filenames.length
      @$('.input-row.url').toggleClass 'has-warning', @client && noFilesFound && @status?
      @$('.locations-info .head-note').toggleClass('no-files', @client && noFilesFound)
        .toggleClass('has-files', @client && !isNoURLError && @filenames.length)

      # Path error.
      @$('.input-row.path').toggleClass 'has-error', @status == 'path_error'

      # Info messages about scan results.
      statusOK = @status == 'ok'
      numMatches = (true for file in @filenames when @scan?.files?[file] == true).length
      @$('.locations-info .foot-note').toggleClass('no-matches', @client && statusOK && !numMatches)
        .toggleClass('all-matches', @client && statusOK && numMatches && numMatches == @filenames.length)
        .toggleClass('some-matches', @client && statusOK && numMatches > 0 && numMatches < @filenames.length)
      if statusOK && numMatches > 0 && numMatches < @filenames.length
        @$('.locations-info .some-matches .num-matches').text numMatches
        @$('.locations-info .some-matches .num-files').html @filenames.length
      @$('.input-row.path').toggleClass 'has-warning', @client && statusOK && !numMatches

      # Visibility of additional inputs
      @$('.input-row.type').toggleClass 'visible', statusOK
      @$('.input-row.missing-files').toggleClass 'visible', statusOK && @model.get('type') == 'css'
      @$('.input-row.stylus-out').toggleClass 'visible', statusOK && @model.get('type') == 'stylus'

      # Disable type selection if decision can be made automatically.
      if @scan?.type == 'css'
        @$('input.type[value=stylus]')[0].setAttribute 'disabled', 'disabled'
      else
        @$('input.type[value=stylus]')[0].removeAttribute 'disabled'

      if @scan?.type == 'stylus'
        @$('input.type[value=css]')[0].setAttribute 'disabled', 'disabled'
      else
        @$('input.type[value=css]')[0].removeAttribute 'disabled'

      @$('.stylus-switch-hint').toggleClass 'visible', statusOK && @model.get('type') == 'css' && @scan?.type == 'css'

      @$('.input-row.stylus-out').toggleClass 'has-warning', @client && statusOK && !@scan?.stylusout && @scan?.stylusoutExists
      @$('.input-row.stylus-out').toggleClass 'has-error', @client && statusOK && !@scan?.stylusoutExists

      @

    updateFileList: ->
      unless client = @model.get 'client'
        return @filenames = []
      css = client.get 'css'
      url = @model.get 'url'
      @filenames = if url.length && url.match /^[a-z]+:\/\/\/?.+$/
        (file.substr url.length for file in css when 0 == file.indexOf url).sort()
      else
        []

    onURLChange: ->
      @model.unset 'novalidate'
      url = @$('input.url').val()
      url += '/' if url.length && url[url.length - 1] != '/'
      @model.set url: url
      @updateFileList()
      @validate =>
        @render()
        @trigger 'validate'

    onPathChange: ->
      return if @_fakeBlur
      path = @toAbsolute @$('input.path').val()
      path += '/' if path.length && path[path.length - 1] != '/'
      @model.set path: path, stylusout: path
      @validate =>
        @render()
        @trigger 'validate'

    onURLFocus: -> @$('.input-row.url').addClass 'editing'
    onURLBlur: -> @$('.input-row.url').removeClass 'editing'

    onEditClick: -> @$('input.url').focus()

    onBrowseClick: ->
      @browse @model.get('path'), (path) =>
        @$('input.path').val path
        @onPathChange()

    onBrowseStylusOutClick: ->
      @browse @model.get('stylusout'), (path) =>
        @$('input.stylus-out').val path
        @onStylusOutChange()

    onTypeChange: ->
      @model.set type: if @$('input.type[value=css]')[0].checked then 'css' else 'stylus'
      @render()

    onConvertClick: ->
      alert 'Sorry. Not implemented yet. You can use "stylus -C" to convert files manually.'

    onMissingFilesChange: ->
      value = @$('input.missing-files').val()

    onStylusOutChange: ->
      path = @toAbsolute @$('input.stylus-out').val()
      path += '/' if path.length && path[path.length - 1] != '/'
      @model.set stylusout: path
      @validate =>
        @render()
        @trigger 'validate'

    validate: (cb) ->
      return cb false if @model.get('novalidate')
      @status = null

      url = @model.get 'url'
      unless url.length
        @status = 'url_empty'
        return cb true
      unless url.match /^[a-z]+:\/\/.+\/.*$/
        @status = 'url_format'
        return cb true

      path = @model.get 'path'
      unless path.length
        @status = 'path_empty'
        return cb true

      unless client = @model.get('client')
        @status = 'ok'
        return cb false
      app.socket.emit 'checkDir', client.id, @model.get('url'), @model.get('path'), @model.get('stylusout'), (results) =>
        if results.status == 'no-directory'
          @status = 'path_error'
          return cb true

        if results.status == 'ok'
          @scan = results
          @status = 'ok'
          if results.type in ['css', 'stylus']
            @model.set type: results.type

          return cb false

    toAbsolute: (path) ->
      path.replace /^\//, app.root
      
    fromAbsolute: (path) ->
      if 0 == path.toLowerCase().indexOf app.root.toLowerCase()
          path = '/' + path.substr app.root.length
      path
      
    onRemove: ->
      $(@el).remove()

    onRemoveClick: ->
      @model.destroy()

    browseFiles: (path, cb) ->
      app.socket.emit 'browseFiles', path, cb

    browse: (current, cb) ->
      win = window.open '', 'dirpicker', 'width=680,height=380,resizable=no,scrollbars=no'
      win.document.body.innerHTML = ''
      require ['lib/views/ui/dirpicker'], (DirPicker) =>
        for link in document.getElementsByTagName('link')
          win.document.body.appendChild node 'link',
            rel: link.getAttribute('rel')
            type: link.getAttribute('type')
            href: window.location.protocol + '//' + window.location.host + link.getAttribute('href')
        for link in document.querySelectorAll('style[data-url]')
          win.document.body.appendChild node 'link',
            rel: 'stylesheet'
            type: 'text/css'
            href: link.getAttribute('data-url')
        win.document.title = "Match source for #{@model.get('url')}"
        dp = new DirPicker provider: @browseFiles, path: @fromAbsolute current
        dp.bind 'select', (path) -> cb path
        dp.bind 'close', -> win.close()
        $(win.document.body).css(overflow: 'hidden').append dp.render().el
        
    startDirectoryComplete: (e) ->
      return if @_fakeBlur
      input = e.target
      $(input)
        .on('keydown', @onDirectoryKeyDown)
        .on('blur', @endDirectoryComplete)
      _.delay => @onDirectoryKeyUp e
      
    onDirectoryKeyUp: (e) ->
      input = e.target
      if input.selectionStart != input.selectionEnd || input.selectionStart != input.value.length
        return @setCompletion input, ''
      
      if !input.value.length
        return @setCompletion input, '/'
      
      if '/' not in input.value
        return @setCompletion input, ''
      
      parts = input.value.split '/'
      path = _.initial(parts).join('/') + '/'
      last = _.last parts
      value = input.value
      selectionStart = input.selectionStart
      selectionEnd = input.selectionEnd
      
      complete = =>
        return unless input.value == value && input.selectionStart == selectionStart && input.selectionEnd == selectionEnd
        dirs = @_completionCache[path]
        @completionOffset = last.length
        @completionMatches = _.filter dirs, (dirname) -> 0 == dirname.indexOf last
        @completionIndex = 0
        _.each @completionMatches, (item, index) =>
          if item.substr(last.length) + '/' == input._completion
            @completionIndex = index
        @setCompletion input
      
      if @_completionCache[path]
        complete()
      else
        @cacheCompletion path, complete
      
    cacheCompletion: (path, cb) ->
      @browseFiles path, ({dirs}) =>
        @_completionCache[path] = dirs
        cb()
        
    onDirectoryKeyDown: (e) ->
      input = e.target
      switch e.keyCode
        when 38 # Up
          if @completionMatches?.length > 1
            @completionIndex--
            @completionIndex = @completionMatches.length - 1 if @completionIndex < 0
            @setCompletion input
          e.stopPropagation()
          e.preventDefault()
        when 40 # Down
          if @completionMatches?.length > 1
            @completionIndex++
            @completionIndex = 0 if @completionIndex >= @completionMatches.length
            @setCompletion input
          e.stopPropagation()
          e.preventDefault()
        when 9, 13 # Tab/Enter.
          return unless input._completion?.length
          input.value += input._completion
          input.setSelectionRange input.value.length, input.value.length
          input.scrollLeft = 1e6
          input._completion = ''
          e.stopPropagation()
          e.preventDefault()
      _.delay => @onDirectoryKeyUp(e)
      
    setCompletion: (input, value) ->
      unless value?
        value = if @completionMatches[@completionIndex] then @completionMatches[@completionIndex].substr(@completionOffset) + '/' else ''
      
      $input = $(input)
      container = $input.closest '.input-container'
      completionPfx = $(container).find '.completion-pfx'
      completionSfx = $(container).find '.completion-sfx'
      completionPfx.html input.value.replace /\s/g, '&nbsp;'
      completionSfx.html value.replace /\s/g, '&nbsp;'
      pfxWidth = parseInt completionPfx.css 'width'
      sfxWidth = parseInt completionSfx.css 'width'
      maxWidth = 267
      if pfxWidth + sfxWidth < maxWidth
        completionSfx.css left: pfxWidth
        $input.css paddingRight: 2
      else
        completionSfx.css left: maxWidth - sfxWidth
        $input.css paddingRight: sfxWidth + 2
      $input.css display: if $input.css('display') == 'inline-block' then 'block' else 'inline-block'
      if ua.isGecko
        @_fakeBlur = true
        $input.blur().focus()
        @_fakeBlur = null
      input._completion = value
      if !value.length
        @completionMatches = null

    endDirectoryComplete: (e) ->
      return if @_fakeBlur
      input = e.target
      @setCompletion input, ''
      $(input)
        .off('keydown', @onDirectoryKeyDown)
        .off('blur', @endDirectoryComplete)

  module.exports =
    URLInput: URLInput
    URLInputList: URLInputList
    URLInputView: URLInputView
