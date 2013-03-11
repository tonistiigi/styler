define (require, exports, module) ->

  require 'vendor/link!css/dirpicker.css'

  {node, style} = require 'lib/utils'

  DirStack = Backbone.View.extend
    className: 'stack'

    events:
      'click .diritem' : 'onSelect'

    initialize: (opt) ->
      @picker = opt.picker
      @path = opt.path
      @selectedItem = null
      @picker.provider (@picker.cleanPath @path), (res) =>
        if res.drives
          for drive in res.drives
            item = node 'div', class: 'item diritem driveitem', 'data-filename': drive, drive
            @el.appendChild item
        dirs = _.sortBy res.dirs, (dirname) -> dirname.toLowerCase()
        for dir in dirs
          item = node 'div', class: 'item diritem', 'data-filename': dir, dir
          @el.appendChild item
        files = _.sortBy res.files, (filename) -> filename.toLowerCase()
        for file in files
          item = node 'div', class: 'item', file
          $(item).addClass if /\.styl$/i.test(file) then 'stylitem' else 'cssitem'
          @el.appendChild item
        @selectFile() if @selectedFile

    selectFile: (filename = @selectedFile) ->
      item =  _.find @$('.item').get(), (item) -> filename == item.getAttribute 'data-filename'
      @selectedFile = filename
      @selectItem item

    selectItem: (item) ->
      if @selectedItem
        $(@selectedItem).removeClass 'selected'
      @selectedItem = item
      $(@selectedItem).addClass 'selected'

    onSelect: (e) ->
      item = e.currentTarget
      path = @path + item.getAttribute 'data-filename'
      @picker.openPath path

    remove: ->
      @$el.remove()

  DirPicker = Backbone.View.extend
    className: 'dirpicker'

    events:
      'click .btn.cancel' : 'cancel',
      'click .btn.select' : 'select'

    initialize: (opt) ->
      @provider = opt.provider
      @stacks = []
      @$el.append node 'div', class: 'stack-scroller-cont',
        @scroller = node 'div', class: 'stack-scroller',
          @stackcont = node 'div', class: 'stack-cont'

      @$el.append node 'div', class: 'buttons',
        node 'div', class: 'btn cancel', 'Cancel'
        node 'div', class: 'btn select', 'Select'
      path = opt.path or '/'
      path = '/' + path if path[0] != '/'
      @openPath path

    openPath: (path) ->
      parts = path.split '/'
      len = parts.length
      len-- if parts[parts.length - 1] == ''
      path = ''
      @clearStacksFromIndex len

      for i in [0...len]
        path += parts[i] + '/'
        stack = @stacks[i]
        if stack
          if stack.path != path
            @clearStacksFromIndex i
          else
            continue
        stack = new DirStack path: path, picker: @
        @stackcont.appendChild stack.render().el
        if @stacks.length
          @stacks[@stacks.length - 1].selectFile parts[i]
        @stacks.push stack
      @path = path
      $(@stackcont).css width: @stacks.length * 180
      _.delay =>
        @scroller.scrollLeft = 10e4
      , 100

    clearStacksFromIndex: (i) ->
      while @stacks.length >= i
        stack = @stacks[@stacks.length - 1]
        stack.remove()
        @stacks.pop()

    close: ->
      @trigger 'close'

    cancel: ->
      @close()

    cleanPath: (path) ->
      parts = path.split '/'
      parts.shift() if parts[1].match /^[a-z]\:$/i
      parts.join '/'

    select: ->
      @trigger 'select', @cleanPath @path
      @close()

  module.exports = DirPicker
