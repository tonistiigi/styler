define (require, exports, module) ->

  ua = require 'ace/lib/useragent'
  keys = require 'ace/lib/keys'
  {node} = require 'lib/utils'
  {addKeyboardListener, formatKeyCommand} = require 'lib/keyboard'

  require 'vendor/link!css/settings.css'

  Settings = Backbone.View.extend

    className: 'overlay'

    template: require 'lib/templates/settings'

    events:
      'click': 'dismissOnOverlay'
      'click .button.close': 'dismiss'
      'click .sheet .title': 'onSheetSelect'
      'click .item .keycommand': 'onKeyCommandChangeRequest'
      'change .theme': 'onThemeChange'
      'change .cbxcontrol': 'onCheckboxChange'
      'change .lintrule': 'onLintRuleChange'

    csslint:
      'Errors': [
        (id: 'box-model', txt: 'Beware of broken box sizing')
        (id: 'display-property-grouping', txt: 'Require properties appropriate for display')
        (id: 'duplicate-properties', txt: 'Disallow duplicate properties')
        (id: 'empty-rules', txt: 'Disallow empty rules')
        (id: 'known-properties', txt: 'Require use of known properties')
      ]
      'Compatibility': [
        (id: 'adjoining-classes', txt: 'Disallow adjoining classes')
        (id: 'box-sizing', txt: 'Disallow box-sizing')
        (id: 'compatible-vendor-prefixes', txt: 'Require compatible vendor prefixes')
        (id: 'gradients', txt: 'Require all gradient definitions')
        (id: 'text-indent', txt: 'Disallow negative text-indent')
        (id: 'vendor-prefix', txt: 'Require standard property with vendor prefix')
      ]
      'Performance': [
        (id: 'font-faces', txt: 'Don\'t use too many web fonts')
        (id: 'import', txt: 'Disallow @import')
        (id: 'regex-selectors', txt: 'Disallow selectors that look like regexs')
        (id: 'universal-selector', txt: 'Disallow universal selector')
        (id: 'zero-units', txt: 'Disallow units for 0 values'),
        (id: 'overqualified-elements', txt: 'Disallow overqualified elements')
        (id: 'shorthand', txt: 'Require shorthand properties')
      ]
      'Maintainability & Duplication': [
        (id: 'floats', txt: 'Disallow too many floats')
        (id: 'font-sizes', txt: 'Don\'t use too many font sizes')
        (id: 'ids', txt: 'Disallow IDs in selectors'),
        (id: 'important', txt: 'Disallow !important')
      ]
      'Accessibility': [
        (id: 'outline-none', txt: 'Disallow outline:none')
      ]
      'OOCSS': [
        (id: 'qualified-headings', txt: 'Disallow qualified headings')
        (id: 'unique-headings', txt: 'Heading should only be defined once')
      ]

    keyboard:
      'Navigation': [
        (id: 'focus-styleinfo', txt: 'Focus Style Info')
        (id: 'focus-tree', txt: 'Focus Elements Outline')
        (id: 'focus-clientswitch', txt: 'Focus Clients Switch')
        (id: 'focus-editor', txt: 'Focus Editor area')
        (id: 'toggle-infobar', txt: 'Toggle Info bar')
        (id: 'toggle-left-pane', txt: 'Toggle Left Pane')
        (id: 'toggle-window-mode', txt: 'Toggle application mode')
        (id: 'start-inspector-mode', txt: 'Start inspector mode')
        (id: 'toggle-iframe-container', txt: 'Toggle Iframe mode')
        (id: 'toggle-cli', txt: 'Toggle command line')
        (id: 'settings', txt: 'Settings')
        (id: 'back-to-project-list', txt: 'Back to project list')
      ]
      'Elements Outline': [
        (id: 'select-next-element', txt: 'Select next element')
        (id: 'select-previous-element', txt: 'Select previous element')
        (id: 'select-down-many', txt: 'Fast move down')
        (id: 'select-up-many', txt: 'Fast move up')
        (id: 'fold-element', txt: 'Fold selection')
        (id: 'unfold-element', txt: 'Unfold selection')
        (id: 'select-outline-subtree', txt: 'Select Subtree')
        (id: 'hide-outline-subtree', txt: 'Hide Subtree')
        (id: 'focus-element-styleinfo', txt: 'Focus selected element\'s style')
        (id: 'scroll-to-view', txt: 'Scroll selected element into view')
      ]
      'Style info' : [
        (id: 'style-item-down', txt: 'Highlight next item')
        (id: 'style-item-up', txt: 'Highlight previous item')
        (id: 'style-selector-down', txt: 'Highlight next rule')
        (id: 'style-selector-up', txt: 'Highlight previous rule')
        (id: 'style-item-expand', txt: 'Expand shorthand item')
        (id: 'style-item-collapse', txt: 'Collapse shorthand item')
        (id: 'style-item-open', txt: 'Open highlighted style in editor')
        (id: 'style-rule-open', txt: 'Open rule in editor', static: 1, mac: '⌥⌘[1-9]', win: 'Ctrl-Shift-[1-9]')
        (id: 'switch-back-to-outline', txt: 'Switch back to outline')
      ]
      'Editor' : [
        (id: 'select-filebrowser', txt: 'Select file browser')
        (id: 'select-tab', txt: 'Select tab', static: 1, mac: '⌘[1-9]', win: 'Ctrl-[1-9]')
        (id: 'save-tab', txt: 'Save tab')
        (id: 'save-all', txt: 'Save all tabs')
        (id: 'close-tab', txt: 'Close tab')
        (id: 'toggle-update-mode', txt: 'Switch update mode')
        (id: 'toggle-tab-mode', txt: 'Switch tab modes')
        (id: 'focus-selector-up', txt: 'Focus previous selector')
        (id: 'focus-selector-down', txt: 'Focus next selector')
        (id: 'search-in-file', txt: 'Search in file')
        (id: 'search-next-result', txt: 'Next search result')
        (id: 'search-previous-result', txt: 'Previous search result')
        (id: 'indent-selection', txt: 'Indent selection')
        (id: 'outdent-selection', txt: 'Outdent selection')
        (id: 'numeric-increment', txt: 'Increment numeric value')
        (id: 'numeric-decrement', txt: 'Decrement numeric value')
        (id: 'numeric-increment-many', txt: 'Multi Increment numeric value')
        (id: 'numeric-decrement-many', txt: 'Multi Decrement numeric value')
        (id: 'select-focused-selector', txt: 'Select (next) element for rule')
        (id: 'select-focused-selector-reverse', txt: 'Select previous element for rule')
        (id: 'edit-value', txt: 'Edit property value')
        (id: 'new-property', txt: 'Add new property')
        (id: 'show-completions', txt: 'Show completions')
      ]

    initialize: ->
      _.bindAll @, 'onKeyDown'

      addKeyboardListener 'settings', @el

      # Disable all key commands for dialog or input for edit mode.
      document.addEventListener 'keydown', @onKeyDown, true

      $(document.body).append @render().el
      
      # Delay to get the transition effect.
      _.delay =>
        @$el.addClass 'is-loaded'
      , 30

    onSheetSelect: (e) -> @selectSheet $(e.currentTarget).parent()

    selectSheet: (el) ->
      @$('.sheet').removeClass 'is-selected'
      $(el).addClass 'is-selected'

    dismissOnOverlay: (e) ->
      return @cancelKeyCommand() if @_keyChangeElement
      @dismiss() if e.target == @el

    dismiss: ->
      document.removeEventListener 'keydown', @onKeyDown, true
      @$el.removeClass 'is-loaded'
      _.delay =>
        @$el.remove()
      , 500

    onKeyDown: (e) ->
      if @_keyChangeElement
        unless keys.MODIFIER_KEYS[e.keyCode]
          key = keys[e.keyCode]
          if key
            key = [key]
            key.unshift 'command' if e.metaKey
            key.unshift 'alt' if e.altKey
            key.unshift 'shift' if e.shiftKey
            key.unshift 'ctrl' if e.ctrlKey
            @saveKeyCommand e, key.join '-'

      else
        if keys.MODIFIER_KEYS[e.keyCode] == 'Esc'
          @dismiss()
        # TODO: Possibility to get some better detection than hard coded.
        else if (String.fromCharCode(e.keyCode).match /[0-9]/) and (e.metaKey || e.ctrlKey)
          tab = parseInt String.fromCharCode(e.keyCode)
          el = @$('.sheet').get tab - 1
          @selectSheet el if el

      e.stopPropagation()
      e.preventDefault()

    onCheckboxChange: (e) ->
      if e.target.id
        ob = {}
        ob[e.target.id] = !!e.target.checked
        app.Settings.save ob

    onThemeChange: (e) ->
      app.Settings.save theme: e.target.value

    onLintRuleChange: (e) ->
      ruleid = e.target.getAttribute 'data-ruleid'
      current = app.Settings.get 'csslint'
      newrules = {}
      newrules[i] = v for i, v of current
      newrules[ruleid] = if e.target.checked then 1 else 0
      app.Settings.save csslint: newrules

    onKeyCommandChangeRequest: (e) ->
      el = e.currentTarget
      @_keyChangeElement = el
      $(el).addClass('edit').html '[press new key]'

      @$el.append hintEl = node 'div', class: 'keyenterhint', 'Press new key combination on your keyboard to change the shortcut. To cancel click anywhere on the screen.'

      if ua.isChrome
        if ua.isMac
          hintKeys = '⌘W, ⌘Q, ⌘N and ⌘T'
        else
          hintKeys = 'Ctrl-N, Ctrl-T, Alt-F4 and Alt-Tab'

        msg = "Please note that Google Chrome does not support overwriting some system shortcuts(like #{hintKeys}). Please try not to use these shortcuts as they may provide unexpected results."

      hintEl.appendChild node 'div', class: 'warningnote', msg if msg

    saveKeyCommand: (e, keyCode) ->
      shortcuts = @model.get 'keyboard_shortcuts'
      el = @_keyChangeElement
      commandId = el.getAttribute 'data-cmd-id'
      newvalue = _.clone shortcuts
      newvalue[cmd_id] = _.clone newvalue[commandId]
      cmd = newvalue[commandId]
      if ua.isMac
        cmd.mac = keyCode
      else
        cmd.win = keyCode
      if cmd.export
        exp = _.extend (if ua.isMac then cmd.export.mac else cmd.export.win), 
          code: e.keyCode
          meta: e.metaKey
          ctrl: e.ctrlKey
          shift: e.shiftKey
          alt: e.altKey
          txt: formatKeyCommand keyCode
      app.Settings.save keyboard_shortcuts: newvalue
      @cancelKeyCommand()
      @highlightDuplicateKeys()

    cancelKeyCommand: (e) ->
      el = @_keyChangeElement
      commandId = el.getAttribute 'data-cmd-id'
      shortcut = @model.get('keyboard_shortcuts')[commandId]
      keyCode = shortcut.mac
      keyCode = shortcut.win if !ua.isMac && shortcut.win
      $(el).removeClass('edit').html formatKeyCommand keyCode

      @$('.keyenterhint').remove()
      @_keyChangeElement = null

    highlightDuplicateKeys: (e) ->
      shortcuts = @model.get 'keyboard_shortcuts'
      duplicates = {}
      codes = _.map shortcuts, (cmd) ->
        (if cmd.scope then cmd.scope else '') + (if ua.isMac then cmd.mac else cmd.win || cmd.mac).toLowerCase()
      names = _.keys shortcuts
      _.each names, (name, i) ->
        return if name in duplicates
        _.each names, (compare, j) ->
          return if i == j
          duplicates[name] = duplicates[compare] = 1 if codes[i] == codes[j]
      @$('.warning').removeClass 'warning'
      @$('.keycommand').each (i, el) ->
        $(el.parentNode).addClass 'warning' if duplicates[el.getAttribute 'data-cmd-id']

    render: ->
      @$el.html @template @model.toJSON()
      @$('.theme').val @model.get 'theme'
      
      # Checkbox controls.
      for name in 'save_icon|line_numbers|invisibles|confirm_keyboard_close|confirm_unsaved_close|autocomplete|statusbar|fpsstats|sidebar_right|devmode'.split '|'
        @$('#' + name)[0].checked = !!@model.get name
      @$('.sheet.editor').addClass 'is-selected'

      # CSSLint inputs.
      lintrules = @model.get 'csslint'
      fragment = document.createDocumentFragment()
      for groupname, options of @csslint
        fragment.appendChild ditem = node 'div', class: 'item',
          node 'div', class: 'lbl', groupname
          dvalue = node 'div', class: 'value'
        for opt in options
          cbox = node 'input', type: 'checkbox', value: 1, class: 'lintrule', 'data-ruleid': opt.id
          cbox.checked = true if !!lintrules[opt.id]
          dvalue.appendChild cbox
          dvalue.appendChild document.createTextNode opt.txt
          dvalue.appendChild node 'br'
      @$('.sheet.csslint .contents .items').append fragment

      # Keyboard shortcuts inputs.
      shortcuts = @model.get 'keyboard_shortcuts'
      fragment = document.createDocumentFragment()
      for groupname, options of @keyboard
        fragment.appendChild dgroup = node 'div', class: 'group',
          node 'div', class: 'group-name', groupname
        for opt in options
          keyCode = shortcuts[opt.id]?.mac
          keyCode = shortcuts[opt.id]?.win if !ua.isMac && shortcuts[opt.id]?.win
          dgroup.appendChild ditem = node 'div', class: 'item',
            node 'div', class: 'lbl', (opt.txt)
            if opt.static
              node 'div', class: 'statickey', (if ua.isMac then opt.mac else opt.win)
            else
              dcmd = node 'div', class: 'keycommand', 'data-cmd-id': (opt.id), (formatKeyCommand(keyCode))

      @$('.sheet.keyboard .contents .items').append fragment
      @highlightDuplicateKeys()
      @

  module.exports = Settings