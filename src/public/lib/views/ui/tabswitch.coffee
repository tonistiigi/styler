define (require, exports, module) ->

  {node, makeToggleFocusable} = require 'lib/utils'

  TabSwitch = Backbone.View.extend
    className: 'tabswitch selectable'

    template: require 'lib/templates/tab_switch'

    events:
      'click': 'onClick'
      'click .option-format': 'onFormatClick'

    initialize: ->
      @project = app.console.project
      @project.on 'change:tabSize', @render, @
      @project.on 'change:softTabs', @render, @
      app.console.state.on 'change:selectedUrl', @render, @
      @$el.attr tabIndex: '3'
      makeToggleFocusable @el
      @render()

    render: ->
      @$el.html @template()
      
      tabSize = @project.get 'tabSize'
      softTabs = @project.get 'softTabs'
      state = app.console.state
      
      @$(".option-size-#{tabSize}").addClass 'is-selected'
      @$el.toggleClass 'no-formatting', !(state.get('selectedUrl').match(/css$/) && state.get('selectedType') == 'css')
      
      @$('.option-type').addClass 'is-selected' if softTabs
      @$('.selection').html (if softTabs then 'Soft tabs:' else 'Tab size:') + " <span>#{tabSize}</span>"
      @
      
    onFormatClick: ->
      app.console.editor.formatCurrentFile()

    onClick: (e) ->
      target = $(e.target)
      if target.hasClass 'option-size'
        tabsize = target[0].getAttribute 'data-tabsize'
        @project.save tabSize: parseInt tabsize

      if target.hasClass 'option-type'
        @project.save softTabs: !@project.get 'softTabs'

  module.exports = TabSwitch