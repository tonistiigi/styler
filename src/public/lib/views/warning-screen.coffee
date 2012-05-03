define (require, exports, module) ->
  
  require 'vendor/link!css/warning_screen.css'
  
  WarningScreen = Backbone.View.extend
  
    id: 'warning-screen'
    
    initialize: (opt) ->
      if opt.name == 'disconnect'
        @template = require 'lib/templates/warning_disconnect'
      else if opt.name?
        @loadTemplate opt.name
      @$el.addClass opt.name
      @render()
      $(document.body).css(backgroundColor: '#fff').empty().append @el

    loadTemplate: (name) ->
      require ['lib/templates/' + name], (template) =>
        @template = template
        @render()
      
    render: ->
      @$el.html @template() if @template
      @

  module.exports = WarningScreen