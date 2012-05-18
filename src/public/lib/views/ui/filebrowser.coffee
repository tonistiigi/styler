define (require, exports, module) ->

  require 'vendor/link!css/filebrowser.css'
  require 'vendor/moment'

  {node} = require 'lib/utils'
  {addKeyboardListener} = require 'lib/keyboard'
  
  ITEM_HEIGHT = 70
  
  FileItem = Backbone.Model.extend
    defaults: ->
      type: 'file'
      file: null
      items: null
      parent: null
    
    getName: ->
      (if @_pfx? then @_pfx + '/' else '') + @get('path')

    getDepth: ->
      parent = @get('parent')
      if parent then parent.getDepth() + (if @empty then 0 else 1) else -1


  FileItemList = Backbone.Collection.extend
    model: FileItem
    
    comparator: (p) ->
      p.get('type')

  FileItemView = Backbone.View.extend
    className: 'file-item'

    events:
      'dblclick' : 'openFile'
      'click .name': 'openFile'
      'click' : 'onClick'

    initialize: ->
      @model.view = @el.view = @
      @model.on 'destroy', @remove, @
      @model.on 'change', @render, @
      
      if @model.get('type') == 'file'
        parsedName = @model.get('file').get('name').match /^(.+)(\.[^\.]+)$/
        @$el.addClass 'is-file'
        @$el.append [ 
          node 'div', class: 'lastmod', (moment(@model.get('file').get('mtime')).fromNow())
          node 'div', class: 'size', '10KB'
          node 'div', class: 'name', (parsedName[1]),
            node 'span', class: 'ext', (parsedName[2])
        ]
      else
        @$el.addClass 'is-dir'
        @$el.append [
          node 'div', class: 'expand-bullet'
          node 'div', class: 'name', (@model.get('path'))
          @itemsEl = node 'div', class: 'items'
        ]
        
        items = @model.get('items')
        items.on 'add', @onItemAdd, @
        items.on 'reset', @onItemAddAll, @
      
      app.console.on 'change:client', @render, @
      
      

    onItemAdd: (item) ->
      view = (new FileItemView model: item, parent: @model).render()
      view.on 'select', (item) =>
        @trigger 'select', item
      index = @model.get('items').indexOf(view.model)
      previous = @model.get('items').at(index - 1)
      previousView  = previous && previous.view;
      if index == 0 || !previous || !previousView
        $(@itemsEl).prepend(view.el)
      else
        $(previousView.el).after(view.el)
      @render()
      
    onItemAddAll: (items) ->
      $(@itemsEl).empty()
      @model.get('items').each @onItemAdd, @

    openFile: ->
      app.console.openFile @model.get('file')?.get 'url'

    onClick: (e) ->
      @select()
      e.stopPropagation()
      e.preventDefault();

    destroy: ->
      @model.off 'destroy', @remove, @
      @model.off 'change', @render, @
      app.console.off 'change:client', @render, @

    select: (bool = true) ->
      @$el.toggleClass 'is-selected', bool
      @trigger 'select', @model if bool
      # Order is important to get the browser clear old ones.
      @selected = bool

    render: ->
      items = @model.get('items')
      
      depth = @model.getDepth()
      unless depth == @lastDepth
        @$el.css paddingLeft: depth * 20
        @lastDepth = depth
      
      return @ unless items
      
      if @model.get('type') == 'dir' && items.size() == 1 && items.at(0).get('type') == 'dir'
        @model.empty = items.at(0)
        @model.empty._pfx = @model.getName()
        @model.empty.view.render()
        @$el.addClass 'is-empty'
      else if @model.empty
        @model.empty._pfx = null
        @model.empty.view.render()
        @model.empty = null
        @$el.removeClass 'is-empty'
      
      $(@$('.name')[0]).text @model.getName()
      
      ###
      json = @model.toJSON()
      clientId = app.console?.client?.id
      parsedName = json.name.match /^(.+)(\.[^\.]+)$/
      _.extend json,
        isActive: clientId && (json.clients.indexOf clientId) != -1
        isOpen: !!json.edit
        name: parsedName[1]
        extension: parsedName[2]
        isHelper: 0 == json.url.indexOf '#local'
      @$el.html @template json
      ###
      @

  FileBrowser = Backbone.View.extend

    initialize: ->
      _.bindAll @, 'onSelect', 'onKeyDown'

      @subviews = []

      @collection.on 'add', @onAddFile, @
      @collection.on 'reset', @onAddAllFiles, @

      addKeyboardListener 'filebrowser', @el
      @el.listenKey 'file-prev', mac: 'down', exec: => @moveSelection 1
      @el.listenKey 'file-next', mac: 'up', exec: => @moveSelection -1
      @el.listenKey 'file-first', mac: 'home', exec: => @collection.first().view.select()
      @el.listenKey 'file-last', mac: 'end', exec: => @collection.last().view.select()
      @el.listenKey 'select-file', mac: 'return', exec: => @selectedFile?.view?.openFile()
      
      @root = new FileItem type: 'dir', path: '', items: new FileItemList
      rootView = new FileItemView model: @root
      rootView.on 'select', @onSelect
      @$el.append rootView.render().el
      
      @$el.on 'keydown', @onKeyDown
      @search = ''

    destroy: ->
      @collection.each (file) -> file.view.destroy()
      @collection.off 'add', @addOne, @
      @collection.off 'reset', @addAll, @

    # As-you-type file search(highlight).
    onKeyDown: (e) ->
      char = String.fromCharCode e.keyCode
      return @search = '' unless char.length && /[\w-\.]/.test char
      curTime = new Date()
      @search = '' if curTime - @lastCharTime > 700
          
      @search += char.toLowerCase()
      @lastCharTime = curTime
      search = @search
      file = null
      filter = (item) ->
        return if file
        if item.get('type') == 'dir'
          item.get('items').each (i) -> filter i
        else if -1 != item.get('file').get('name').toLowerCase().indexOf search
          file = item
      filter @root
      file?.view?.select()

    moveSelection: (delta) ->
      selectedFile = @selectedFile
      items = @$('.file-item')
      items = _.filter items, (item) -> !$(item).hasClass 'is-empty'
      index = items.indexOf selectedFile?.view.el || items[0]
      index += delta
      index = 1 if index < 1
      index = items.length - 1 if index >= items.length
      items[index].view.select()
      event.preventDefault()

    getParent: (item, path) ->
      return item if !path.length || path.length == 1 && path[0] == item.get('path')
      items = item.get('items')
      
      found = false
      items.each (subitem) =>
        if subitem.get('type') == 'dir' && subitem.get('path') == path[0]
          found = @getParent subitem, path[1..]
      return found if found
      
      newitem = new FileItem parent: item, path: path[0], type: 'dir', items: new FileItemList
      items.add newitem
      
      return @getParent newitem, path[1..]

    onAddFile: (file) ->
      path = file.get('url').replace /\/[^\/]*$/, ''
      path = 'locals' if /^#local/.test file.get('url')
      parent = @getParent @root, path.split('/')
      
      fileitem = new FileItem type: 'file', file: file, parent: parent
      parent.get('items').add fileitem

    onAddAllFiles: ->
      @collection.each @onAddFile, @
      
    onSelect: (file) ->
      selectedFile = @selectedFile
      @selectedFile = file
      return if !selectedFile || selectedFile == file
      selectedFile.view.select false
      file.view.el.scrollIntoViewIfNeeded?();


  module.exports = FileBrowser