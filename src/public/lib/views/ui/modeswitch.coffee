define (require, exports, module) ->

  {node, makeToggleFocusable} = require 'lib/utils'

  ModeSwitch = Backbone.View.extend

    className: 'modeswitch selectable'

    template: require 'lib/templates/mode_switch'

    events:
      'click': 'onClick'

    initialize: ->
      @project = app.console.project
      @project.on 'change:mode', @render, @

      @$el.attr tabIndex: '4'
      makeToggleFocusable @el
      @render()

    render: ->
      @$el.html @template()
      mode = @project.get 'mode'
      if mode
        @$('.mode-live').addClass 'is-selected'
        @$('.selection').html 'Updates: <span>live</span>'
      else
        @$('.mode-save').addClass 'is-selected'
        @$('.selection').html 'Updates: <span>on save</span>'

      @

    onClick: (e) ->
      if $(e.target).hasClass 'mode-live'
        @project.save mode: 1
      if $(e.target).hasClass 'mode-save'
        @project.save mode: 0
        
  module.exports = ModeSwitch