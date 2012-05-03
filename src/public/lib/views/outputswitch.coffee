define (require, exports, module) ->

  require 'vendor/link!css/outputswitch.css'
  {addKeyboardListener} = require 'lib/keyboard'
  {makeToggleFocusable} = require 'lib/utils'

  # TODO: Rename to ClientSwitch
  OutputSwitch = Backbone.View.extend
    template: require 'lib/templates/output_switch'

    className: 'client-switch'

    events:
      'click .item' : 'onItemSelect'
      'mouseover .item' : 'onMouseOver'

    initialize: ->
      @model.on 'clients:add', @render, @
      @model.on 'clients:remove', @render, @
      @selectedId = 0
      @highlightedId = 0
      
      makeToggleFocusable @el
      
      addKeyboardListener 'clientswitch', @el
      @el.listenKey 'move-down', mac: 'down', exec: => @moveHighlight 1
      @el.listenKey 'move-up', mac: 'up', exec: => @moveHighlight -1
      @el.listenKey 'select-client', mac: 'return', exec: => @selectId @highlightedId

    select: (@client) ->
      @selectId @client?.id

    selectId: (@selectedId) ->
      @highlight @selectedId
      @trigger 'change', app.Clients.get @selectedId if @_notFirst
      @render()
      @el.blur()
      @_notFirst = true

    onItemSelect: (e) ->
      clientId = parseInt (e.currentTarget.getAttribute 'data-client-id'), 10
      @selectId clientId unless clientId == @selectedId

    moveHighlight: (delta) ->
      clients = @model.getClients()
      index = clients.indexOf _.find clients, (client) => client.id == @highlightedId
      return unless index != -1
      index += delta
      index = clients.length - 1 if index < 0
      index = 0 if index >= clients.length
      @highlight clients[index].id

    highlight: (id) ->
      clients = @model.getClients()
      items = @$('.item')
      items.removeClass 'is-highlight'
      @highlightedId = id
      index = clients.indexOf _.find clients, (client) -> client.id == id
      if items.length && index != -1
        $(items.get(index)).addClass 'is-highlight'

    onMouseOver: (e) ->
      clientId = parseInt (e.currentTarget.getAttribute 'data-client-id'), 10
      @highlight clientId unless clientId == @highlightedId

    render: ->
      selectedClient = app.Clients.get @selectedId
      @$el.html @template
        clients: (_.map @model.getClients(), (client) -> client.toJSON())
        selectedClient: if selectedClient then selectedClient.toJSON() else useragent: 'No clients connected'
      @highlight @selectedId if selectedClient
      tm('outputrender')
      @

  module.exports = OutputSwitch