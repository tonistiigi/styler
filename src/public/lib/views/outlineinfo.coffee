define (require, exports, module) ->

  {highlightSelector, makeToggleFocusable, node} = require "lib/utils"

  require 'vendor/link!css/outline_info.css'

  # TODO: Rename to ClientSwitch
  OutlineInfo = Backbone.View.extend
    template: require 'lib/templates/outline_info'
    
    events:
      'click .pseudo-selector .option': 'pseudoOptionSelect'
      'click .parent-selector .option': 'parentOptionSelect'
      'click .media-selector .option': 'mediaOptionSelect'
      'click .pseudo-indicator': 'onPseudoClick'

    initialize: ->
      @console = app.console
      @console.on 'load:selector', @onSelectorLoaded, @
      @console.on 'load:styles', @onStylesLoaded, @
      @console.on 'change:pseudo', @onPseudoChange, @
      @console.on 'change:media', @onMediaChange, @
      @console.on 'change:focusedselector', @onFocusSelector, @
      @console.on 'unload:client', @onUnloadClient, @
      @$el.html @template()
      
      makeToggleFocusable @$('.pseudo-selector')[0]
      makeToggleFocusable @$('.parent-selector')[0]
      makeToggleFocusable @$('.media-selector')[0]
      @$el.addClass 'is-empty'
    
    mediaOptionSelect: (e) ->
      dataClass = e.currentTarget.getAttribute 'data-class'
      return unless dataClass
      @console.setMedia dataClass
      
    onMediaChange: (e) ->
      @renderMedia()
      
    renderMedia: ->
      media = @console.getMedia()
      el = @$('.media-selector')
      for klass in ['screen', 'print', 'tv']
        selected = klass == media
        el.toggleClass klass, selected
        el.find('.option.' + klass).toggleClass 'is-selected', selected
    
    parentOptionSelect: (e) ->
      index = $('.parent-selector .option').indexOf e.currentTarget
      @console.selectParentAtIndex index + 1

    onPseudoChange: (pseudo) ->
      return unless !pseudo || pseudo.elementId == @console.outline.selectedId()
      @renderPseudos()
    
    pseudoOptionSelect: (e) ->
      dataClass = e.currentTarget.getAttribute 'data-class'
      return unless dataClass
      
      @console.setPseudoValue @console.outline.selectedId(), dataClass
        
    onPseudoClick: (e) ->
      dataClass = e.currentTarget.getAttribute 'data-class'
      return unless dataClass
      @console.setPseudoValue @console.outline.selectedId(), dataClass, false
    
    onUnloadClient: ->
      @$el.addClass 'is-empty'
    
    onSelectorLoaded: (id, selector) ->
      @$el.toggleClass 'is-empty', id == -1
      
      selectorEl = @$('.selector')
      selectorParts = selector.selector.split(" ")
      selectorEl.empty().append highlightSelector _.last selectorParts
      
      parentSelectorEl = @$('.parent-selector > .options')
      parentSelectorEl.empty()
      _.chain(selectorParts.reverse()).tail().each (part) ->
        parentSelectorEl.append node 'div', class: 'option', part
      @$('.parent-selector').toggle selectorParts.length > 1
      @renderPseudos()
    
    renderPseudos: ->
      id = @console.outline.selectedId()
      pseudo = @console.pseudos.find (p) -> p.elementId == id
     
      if pseudo
        classes = pseudo.get 'pseudos'
        for klass in ['hover', 'focus', 'active', 'visited']
          selected = klass in classes
          @$('.pseudo-indicator.' + klass).toggleClass 'is-selected', selected
          @$('.option.' + klass).toggleClass 'is-selected', selected
      else
        @$('.pseudo-indicator').removeClass 'is-selected'
        @$('.pseudo-selector > .option').removeClass 'is-selected'
        
    onStylesLoaded: (id, rules) ->
      return unless id == @console.outline.selectedId()
      @rules = rules
      @renderRuleInfo()
      
    onFocusSelector: ->
      @renderRuleInfo()
    
    renderRuleInfo: ->
      selectedId = @console.outline.selectedId()
      numRules = @rules?.length
      
      hasRuleInfo = numRules && @console.focusedSelectorElements
      @$el.toggleClass 'has-ruleinfo', hasRuleInfo
      
      ruleinfoEl = @$('.element-rules > .inner')
      if hasRuleInfo
        selectedFocused = @console.focusedSelectorElements.indexOf selectedId
        if selectedFocused != -1
          # Reverse lookup.
          selectedFocused = -1
          selectorParts = @console.focusedSelector.split ','
          _.each @rules, ([file, rule], i) ->
            selectedFocused = i if rule in selectorParts

        if selectedFocused == -1
          ruleinfoEl.text "#{numRules} rule#{if numRules > 1 then 's' else ''}"
          @console.styleInfo.focusSelector null
        else
          ruleinfoEl.text "#{selectedFocused + 1} / #{numRules}"
          @console.styleInfo.focusSelector @console.focusedSelector
      else
        ruleinfoEl.text ''
          
  module.exports = OutlineInfo