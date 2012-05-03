define (require, exports, module) ->
  {parallel, combineUrl, getPart, clearEndSpaces} = require 'lib/utils'


  # Abstract Completer class
  class BaseCompleter
    # Parse configuration string to options array.
    # Configuration string is | delimited
    # Number as a second part of the item marks priority.
    _parseConf: (conf) ->
      parts = conf.split '|'
      parts = _.map parts, (p) ->
        [name, priority] = p.split ','
        name: name, priority: parseInt priority or 0
      parts.sort (a, b) ->
        if a.priority > b.priority
          -1
        else if a.priority < b.priority
          1
        else if a.name < b.name
          -1
        else if a.name > b.name
          1
        else
          0

      _.map parts, (i) -> i.name


  # Completes one item from collection
  class ValueCompleter extends BaseCompleter
    constructor: (conf) ->
      @options = @_parseConf conf

    complete: (value, offset, format, cb) ->
      value = clearEndSpaces value, offset
      return cb() if value.length != offset
      value = value.toLowerCase()
      items = _.filter @options, (item) -> item.toLowerCase().indexOf(value) == 0
      cb items:(_.map items, (i) -> value: i, offset: offset)

    matches: (value) ->
      value.toLowerCase() in @options


  # Completes units to a number
  class UnitCompleter extends BaseCompleter
    constructor: (conf) ->
      @options = @_parseConf conf
      @regexp = new RegExp '^[0-9]+('+ (@options.join '|') + ')$', 'i'

    complete: (value, offset, format, cb) ->
      return cb() if value.length != offset
      match = value.match /^-?[\.0-9]+/
      return cb() if !match or value == '0'
      unit = value.substr match[0].length
      items = _.filter @options, (item) -> item.indexOf(unit) == 0
      cb items:(_.map items, (i) -> value: i, offset: offset - match[0].length)

    matches: (value) ->
      !!value.match @regexp


  # Completes one of the subcompleters.
  class AnyCompleter
    constructor: (subs...) ->
      @subs = []
      _.each subs, @addSub, @

    addSub: (sub) ->
      sub = completer: sub unless sub.completer?
      sub.empty = false unless sub.empty
      if sub.completer
        @subs.push sub
      @

    findCompleters: -> @subs

    complete: (value, offset, format, cb) ->
      subs = @findCompleters value, format
      return cb [] if !subs?.length
      items = []
      parallel subs, (sub, done) =>
        return done() if value.length == 0 && subs.length > 1 && !sub.empty
        sub.completer.complete value, offset, format, (completions) ->
          items.push i for i in completions.items if completions?.items
          done()
      , -> cb items:(_.uniq items, false, (i) -> i.value)

    matches: (value) ->
      for sub in @subs
        return true if sub.completer.matches value
      false


  # Completes one part of the value with subcompleter.
  class MultiCompleter
    constructor: (subs...) ->
      @separator = ' '
      @subs = []
      _.each subs, @addSub, @

    addSub: (sub) ->
      sub = completer: sub unless sub.completer?
      sub.limit = 100 unless sub.limit
      sub.empty = false unless sub.empty
      @subs.push sub if sub.completer
      @

    setSeparator: (@separator) -> @

    complete: (value, offset, format, cb) ->
      #debugger;
      active = getPart value, @separator, offset
      completer = @findCompleter active
      return cb() unless completer

      completer.complete active.txt, active.offset, format, cb

    findCompleter: (active) ->
      subs = (_.clone sub for sub in @subs)
      
      for part, i in active.parts when active?.i != i
        for sub in subs
          if sub.limit > 0 and sub.completer.matches part
            sub.limit--
            break

      # Make anycompleter from possible matches.
      compl = new AnyCompleter
      compl.addSub sub for sub in subs when sub.limit > 0
      compl

    matches: (value) ->
      false


  # Completes a comma separated list
  class ListCompleter extends MultiCompleter
    constructor: (@subs...) ->
      @setSeparator ','

    complete: (value, offset, format, cb) ->
      active = getPart value, @separator, offset
      active.i = 0 unless value.length
      compl = @findCompleter active
      return cb() unless compl && active.txt? && active.i < @subs.length

      # Add ', ' as suffix when completion isn't partial and limit isn't reached.
      compl.complete? active.txt, active.offset, format, (completion) =>
        items = completion?.items
        return cb() unless items
        _.each items, (i) =>
          unless i.incomplete
            if active.i < active.parts.length - 1
              i.cursor = 1 unless i.cursor?
              i.incomplete = true
            else if active.i < @subs.length
              i.sfx = (i.sfx ?= '') + ', ' unless i.cursor?
              i.incomplete = true
        cb items:items

    findCompleter: (active) ->
      if active?.i? then @subs[active.i] else null


  # Completes a string with optional quotes.
  # Quotes are added when string starts with a qoute or contains a space.
  class QuotesCompleter extends BaseCompleter
    constructor: (@base) ->

    complete: (value, offset, format, cb) ->
      addQuote = false
      quote = ''

      if value[0] in "'\""
        quote = value[0]
        value = value.substr 1
        offset--
        if value[-1..][0] == quote
          value = value[...-1]
        else
          addQuote = true
      @base.complete value, offset, format, (completion) ->
        items = completion?.items
        return cb() unless items

        items = _.map items, (i) ->
          return i if i.incomplete
          # TODO: ugly!
          _quote = quote
          _addQuote = addQuote
          hasspace = !!i.value.match /\s/
          if hasspace && !_quote
            _pfx = _quote = '"'
            _addQuote = true
          if _quote
            _sfx = _quote
            padd = 1 unless _addQuote

          if _pfx
            if i.pfx? then i.pfx = _pfx + i.pfx else i.pfx = _pfx
          if _sfx
            if i.sfx? then i.sfx += _sfx else i.sfx = _sfx
          if padd
            if i.padd? then i.padd += _padd else i.padd = padd

          i
        cb items:items

    matches: (value) ->
      if value[0] in "'\""
        value[0] == value[-1..][0] and @base.matches value.substr 1, value.length - 2
      else
        @base.matches value


  # Completes a function name and body.
  class FunctionCompleter extends BaseCompleter
    constructor: (@options) ->
      @regexp = new RegExp '^(' + (_.map @options, (o) -> o.name).join('|') + ')\\(.*\\)$', 'i'

    complete: (value, offset, format, cb) ->
      value = value.toLowerCase()
      # Complete function name.
      if value.length == offset #and value.length
        res = _.select @options, (o) -> 0 == (o.name+'()').indexOf(value) and value.length <= o.name.length
        if res.length
          return cb items:_.map(res, (o)-> value: o.name+'()', offset: offset, cursor: -1, func: 1)

      # Forward body to subcompleters.
      parenindex = value.indexOf '('
      return cb() unless parenindex > 0 and sub = _.find(@options, (o) -> o.name == value.substr 0, parenindex)
      addParen = true
      cursor = 0
      subval = value.substr parenindex + 1
      if subval[-1..][0] == ')'
        subval = subval[...-1]
        addParen = false
        cursor = 1

      offset -= parenindex + 1
      sub.completer.complete subval, offset, format, (completion) ->
        items = completion?.items
        return cb() unless items

        items = _.map items, (i) ->
          unless i.incomplete
            if addParen
              if i.sfx? then i.sfx += ')' else i.sfx = ')'
            if cursor
              if i.cursor? then i.cursor += cursor else i.cursor = cursor
          i
        cb items:items

    matches: (value) ->
      !!value.match? @regexp


  # Completes a url('path/to/file') function.
  class UrlCompleter extends FunctionCompleter
    constructor: ->
      super [name:'url', completer: new QuotesCompleter new PathCompleter]


  # Completes a a path(folders and images) based on current file location.
  class PathCompleter extends BaseCompleter
    constructor: ->
      @regexp = /[a-z0-9-_\/\.]/i

    complete: (value, offset, format, cb) ->
      return cb() unless offset == value.length

      index = value.search /([\(\/'"][^\(\/'"]*$)/
      offset -= 1 + index
      val = value.substr index + 1

      if val.length && 0 == '..'.indexOf val
        return cb items: [value: '../', offset: offset, incomplete: 1]

      baseUrl = app.console.getCurrentFile()
      url = combineUrl baseUrl, value

      return cb() unless url
      app.console.callAPI 'GetImgList', url: url, (list) ->
        return cb() unless list
        params = items: (_.map list, (i) ->
          item = value: i, offset: offset
          if i[-1..][0] == '/'
            item.incomplete = 1
          else
            item.preview = url
          item)
        cb params


  # Completes font name based on the other font names found in the project.
  class UsedFontCompleter extends BaseCompleter
    complete: (value, offset, format, cb) ->
      value = value.toLowerCase()
      fonts = app.stats?.fonts.items

      return cb() unless fonts and value.length == offset
      items = _.select fonts, (f) -> -1 != f.name.toLowerCase().indexOf value
      items = _.sortBy items, (f) -> -f.count
      cb items:(_.map items, (i) -> value: i.name, offset: offset)

    matches: (value) ->
      fonts = app.stats?.fonts.items
      value = value.toLowerCase()
      if fonts
        return _.find fonts, (f) -> f.name.toLowerCase() == value
      false

  class ExtendedSelectorCompleter extends ValueCompleter
    constructor: ->
    complete: (value, offset, format, cb) ->
      tab = app.console.editor.tabs.selectedTab()
      cursor = tab.session.selection.getCursor()
      lines = tab.contentManager.outlinelines
      @options = []
      for line, val of lines when line < cursor.row
        @options.push name for name in val.name
      super value, offset, format, cb

  # Completes a hexadecimal color value (#abc123 and #eee).
  class HexColorCompleter extends BaseCompleter
    constructor: ->
      @regexp = /^#[0-9a-f]{3,6}$/i

    complete: (value, offset, format, cb) ->
      value = value.toLowerCase()
      stats = app.stats?.colors.items
      #console.log('hex', value, offset)
      return cb [] unless stats and value.length == offset
      items = _.select stats, (c) -> c.hex && (-1 != c.hex.indexOf value) && c.hex.length > value.length
      items = _.sortBy items, (c) -> c.count
      cb items:(_.map items, (i) -> value: i.hex, offset: offset, color:1)

    matches: (value) ->
      !!value.match @regexp

  # Completes a rgb() or rgba() color value.
  class RgbColorCompleter extends BaseCompleter
    constructor: ->
      @regexp = /^rgba?\s*\([0-9\s\.%]{5,}\)$/i

    complete: (value, offset, format, cb) ->
      value = value.toLowerCase()
      stats = app.stats?.colors.items
      padd = 0
      return cb() unless stats and value.length
      if offset + 1 == value.length && value[value.length - 1] == ')'
        value = value.substr 0, value.length - 1
        padd = 1
      return cb() unless offset == value.length
      mode_rgb = 0 == 'rgb('.indexOf (value.substr 0, 4)
      mode_rgba = 0 == 'rgba('.indexOf (value.substr 0, 5)
      r = g = b = a = null

      return cb() unless mode_rgb or mode_rgba

      # TODO: get rid of this spaghetti.
      val = value.replace /^rgba?\s*\(\s*/i, ''
      while val.length != value.length && val.length
        r = (val.match /^[0-9]+/)?[0]
        return cb() unless r
        val = val.substr r.length
        break unless val.length
        sep = (val.match /^\s*,?\s*/)[0]
        return cb() unless sep
        val = val.substr sep.length
        break unless val.length

        g = (val.match /^[0-9]+/)[0]
        return cb() if !g
        val = val.substr g.length
        break unless val.length
        sep = (val.match /^\s*,?\s*/)[0]
        return cb() unless sep
        val = val.substr sep.length
        break unless val.length

        b = (val.match /^[0-9]+/)[0]
        return cb() if !b
        val = val.substr b.length
        break unless val.length
        sep = (val.match /^\s*,?\s*/)[0]
        return cb() unless sep
        val = val.substr sep.length
        break unless val.length

        if value[3] == 'a'
          a= (val.match /^[0-9\.]+/)[0]
          return cb() if !a
          val = val.substr a.length
          return cb() unless val.length
        break

      items = _.select stats, (c) -> c.rgb && (r==null || 0 == c.rgb[0].toString().indexOf r) && (g==null || 0 == c.rgb[1].toString().indexOf g) && (b==null || 0 == c.rgb[2].toString().indexOf b) && (a==null || 0 == c.rgb[3].toString().indexOf a)
      items = _.sortBy items, (c) -> c.count
      cb items:(_.map items, (i) ->
        rgba = value[3] == 'a' || i.rgb[3] != 1
        val = 'rgb'
        val += 'a' if rgba
        val += '(' + i.rgb[0] + ',' + i.rgb[1] + ',' +i.rgb[2]
        val += ',' +i.rgb[3] if rgba
        val += ')'
        value: val, offset: offset, color:1, padd:padd)

    matches: (value) ->
      !!value.match @regexp
      
  class ColorPickerDialogCompleter extends BaseCompleter
    complete: (value, offset, format, cb) ->
      return cb null unless !value.length || value.match /^#[a-f0-9]{0,6}$/i
      return cb null if offset == value.length && value.length in [4, 7]
      cb items: [value: 'Open picker', offset: 0, exec: (editor, coord) -> editor.commands?.startColorPicker(false, coord)]
      
    matches: -> false

  # Completes a mixed color value.
  class ColorCompleter extends AnyCompleter
    constructor: ->
      super()
      colorchange = new ListCompleter @, new BaseCompleter
      # TODO: should not complete if not stylus.
      @addSub @stylusFunctions = new FunctionCompleter [
        (name:'darken', completer: colorchange)
        (name:'lighten', completer: colorchange)
        (name:'saturate', completer: colorchange)
        (name:'desaturate', completer: colorchange)
        (name:'fade-out', completer: colorchange)
        (name:'fade-in', completer: colorchange)
        (name:'spin', completer: colorchange)
        (name:'dark', completer: @)
        (name:'light', completer: @)
      ]
      @addSub completer: new ColorPickerDialogCompleter(), empty: true
      @addSub completer: new ValueCompleter('aliceblue|antiquewhite|aqua|aquamarine|azure|beige|bisque|black|blanchedalmond|blue|blueviolet|brown|burlywood|cadetblue|chartreuse|chocolate|coral|cornflowerblue|cornsilk|crimson|cyan|darkblue|darkcyan|darkgoldenrod|darkgray|darkgreen|darkgrey|darkkhaki|darkmagenta|darkolivegreen|darkorange|darkorchid|darkred|darksalmon|darkseagreen|darkslateblue|darkslategray|darkslategrey|darkturquoise|darkviolet|deeppink|deepskyblue|dimgray|dimgrey|dodgerblue|firebrick|floralwhite|forestgreen|fuchsia|gainsboro|ghostwhite|gold|goldenrod|gray|green|greenyellow|grey|honeydew|hotpink|indianred|indigo|ivory|khaki|lavender|lavenderblush|lawngreen|lemonchiffon|lightblue|lightcoral|lightcyan|lightgoldenrodyellow|lightgray|lightgreen|lightgrey|lightpink|lightsalmon|lightseagreen|lightskyblue|lightslategray|lightslategrey|lightsteelblue|lightyellow|lime|limegreen|linen|magenta|maroon|mediumaquamarine|mediumblue|mediumorchid|mediumpurple|mediumseagreen|mediumslateblue|mediumspringgreen|mediumturquoise|mediumvioletred|midnightblue|mintcream|mistyrose|moccasin|navajowhite|navy|oldlace|olive|olivedrab|orange|orangered|orchid|palegoldenrod|palegreen|paleturquoise|palevioletred|papayawhip|peachpuff|peru|pink|plum|powderblue|purple|red|rosybrown|royalblue|saddlebrown|salmon|sandybrown|seagreen|seashell|sienna|silver|skyblue|slateblue|slategray|slategrey|snow|springgreen|steelblue|tan|teal|thistle|tomato|turquoise|violet|wheat|white|whitesmoke|yellow|yellowgreen|transparent')
      @addSub completer: new HexColorCompleter, empty: true
      @addSub new RgbColorCompleter

    findCompleters: ->
      if @format != 'stylus'
        _.filter @subs, (sub) => sub.completer != @stylusFunctions
      else
        @subs
        
    complete: (value, offset, format, cb) ->
      @format = format
      super value, offset, format, (res) ->
        cb items:(_.map res?.items,  (i) ->
          i.color = 1 unless i.func || i.exec
          i)

  makeArrayCompleterSingle = (base) -> new MultiCompleter().setSeparator(',').addSub(
    completer:new MultiCompleter().addSub(completer:base, limit: 1, empty: true), empty: true)

  makeArrayCompleter = (base) -> new MultiCompleter().setSeparator(',').addSub(completer:base, empty: true)


  unitCompleter = new UnitCompleter 'px,10|mm,1|cm,1|in,2|pt,1|pc,1|%,5|em,3|ex,1|ch|rem|vh|vw|vm'
  unitCompleterInherit = new AnyCompleter(unitCompleter, new ValueCompleter('inherit'))
  unitCompleterInheritAuto = new AnyCompleter(unitCompleter, new ValueCompleter('inherit|auto'))
  unitCompleterAuto = new AnyCompleter(unitCompleter, new ValueCompleter('auto'))

  colorCompleter = new ColorCompleter()
  imageCompleter = new AnyCompleter()
    .addSub(completer: new UrlCompleter(), empty: true)
    .addSub(completer: new ValueCompleter 'none')

  fontFamilyCompleter = new QuotesCompleter(new AnyCompleter()
    .addSub(empty: true, completer: new UsedFontCompleter())
    .addSub(empty: true, completer: new ValueCompleter 'serif|sans-serif|cursive|fantasy|monospace|Georgia|Palatino Linotype|Book Antiqua|Palatino|Times New Roman|Times|Arial|Helvetica|Arial Black|Gadget|Comic Sans MS|Impact|Charcoal|Lucida Sans Unicode|Lucida Grande|Tahoma|Geneva|Trebuchet MS|Verdana'))

  stylusCompletions = {}
  completions = {}
  completions['border-image-source'] = completions['list-style-image'] = imageCompleter
  completions.color = completions['background-color'] = completions['border-color'] = completions['border-bottom-color'] = completions['border-top-color'] = completions['border-left-color'] = completions['border-right-color'] = completions['column-rule-color'] = completions['outline-color'] = completions['text-decoration-color'] = colorCompleter
  completions.position = new ValueCompleter 'absolute|fixed|inherit|relative|static'
  completions.display = new ValueCompleter 'block|inline|inline-block|inline-table|list-item|none|table|table-caption|table-cell|table-column|table-column-group|table-header-group|table-footer-group|table-row|table-row-group'
  completions.float = new ValueCompleter 'inherit|left|none|right'
  completions.clear = new ValueCompleter 'both|inherit|left|none|right'
  completions.direction = new ValueCompleter 'ltr|rtl|inherit'
  completions['unicode-bidi'] = new ValueCompleter 'normal|embed|bidi-override|inherit'
  completions['box-sizing'] = new ValueCompleter 'border-box|content-box|padding-box'
  completions['list-style-type'] = new ValueCompleter 'disc|circle|square|decimal|decimal-leading-zero|lower-roman|upper-roman|lower-greek|lower-alpha|lower-latin|upper-alpha|upper-latin|armenian|georgian|hebrew|cjk-ideographic|hiragana|katakana|hiragana-iroha|katakana-iroha'
  completions['list-style-position'] = new ValueCompleter 'inside|outside|inherit'

  completions['border-style'] = completions['border-bottom-style'] = completions['border-top-style'] = completions['border-left-style'] = completions['border-right-style'] = new ValueCompleter 'none|hidden|dashed|dotted|double|groove|inset|outset|ridge|solid,10'

  completions['outline-style'] = new ValueCompleter 'none|hidden|dashed|dotted|double|groove|inset|outset|ridge|solid,10|auto|inherit'

  completions['font-style'] = new ValueCompleter 'normal|italic|oblique|inherit'
  completions['text-transform'] = new ValueCompleter 'capitalize|uppercase|lowercase|none|inherit'
  completions.overflow = completions['overflow-x'] = completions['overflow-y'] = new ValueCompleter 'visible|hidden|scroll|auto|inherit'
  completions['empty-cells'] = new ValueCompleter 'show|hide|inherit'
  completions['font-variant'] = new ValueCompleter 'normal|small-caps|inherit'
  completions['font-weight'] = new ValueCompleter 'normal,2|bold,3|bolder|lighter|100|200|300|400|500|600|700|800|900|inherit'
  completions['font-stretch'] = new ValueCompleter 'inherit|ultra-condensed|extra-condensed|condensed|semi-condensed|normal|semi-expanded|expanded|extra-expanded|ultra-expanded|wider|narrower'
  completions['font-size-adjust'] = new ValueCompleter 'none|inherit'
  
  completions['font-size'] = new AnyCompleter(unitCompleter)
    .addSub(completer: new ValueCompleter('xx-small|x-small|small,2|medium,3|large,1|x-large|xx-large|smaller|larger|inherit'), empty: true)

  completions['outline-width'] = completions['border-width'] = completions['border-top-width'] = completions['border-right-width'] = completions['border-bottom-width'] = completions['border-left-width'] = new AnyCompleter(unitCompleter, completer: new ValueCompleter('thin,3|medium,2|thick,1|inherit'), empty: true)

  completions['width'] = completions['height'] = completions['left'] = completions['top'] = completions['right'] = completions['bottom'] = unitCompleterInheritAuto

  completions['min-width'] = completions['min-height'] = completions['max-width'] = completions['max-height'] = new AnyCompleter(unitCompleter, new ValueCompleter 'inherit|none')

  completions['hyphens'] = new ValueCompleter 'none|manual|auto'
  completions['image-rendering'] = new ValueCompleter 'auto|inherit|optimizeSpeed|optimizeQuality|-moz-crisp-edges|-o-crisp-edges|-webkit-optimize-contrast'
  completions['letter-spacing'] = completions['line-height'] = new AnyCompleter(unitCompleter, completer: new ValueCompleter('normal'), empty: true)
  completions['visibility'] = completions['backface-visibility'] = new ValueCompleter 'visible,2|hidden,3|collapse|inherit'
  completions['vertical-align'] = new AnyCompleter(unitCompleter, new ValueCompleter 'baseline|sub|super|text-top|text-bottom|middle,3|top,3|bottom,3|inherit')
  completions['text-align'] = new ValueCompleter 'left,4|center,4|right,4|justify,3|start|end|inherit'
  completions['white-space'] = new ValueCompleter 'normal|pre|nowrap,3|pre-wrap|pre-line|inherit'
  completions['pointer-events'] = new ValueCompleter 'auto|none,3|visiblePainted|visibleFill|visibleStroke|visible| painted|fill|stroke|all|inherit'
  completions['resize'] = new ValueCompleter 'none|both|horizontal|vertical|inherit'
  completions['cursor'] = new ValueCompleter 'auto|default|none|context-menu|help|pointer,3|progress|wait|cell| crosshair|text|vertical-text|alias|copy|move|no-drop|not-allowed|e-resize|n-resize|ne-resize|nw-resize|s-resize|se-resize|sw-resize|w-resize|ew-resize|ns-resize|nesw-resize|nwse-resize|col-resize|row-resize|all-scroll|inherit'
  completions['ime-mode'] = new ValueCompleter 'auto|normal|active|inactive|disabled'
  completions['caption-side'] = new ValueCompleter 'top|bottom|left|right|inherit'
  completions['border-collapse'] = new ValueCompleter 'collapse|separate|inherit'

  completions['padding-top'] = completions['padding-right'] = completions['padding-bottom'] = completions['padding-left'] = completions['outline-offset'] = unitCompleterInherit
  completions['margin-top'] = completions['margin-right'] = completions['margin-bottom'] = completions['margin-left'] = unitCompleterInheritAuto

  completions['padding'] = new MultiCompleter().addSub completer:unitCompleterInherit, limit: 4
  completions['margin'] = new MultiCompleter().addSub completer:unitCompleterInheritAuto, limit: 4
  completions['marks'] = new AnyCompleter()
    .addSub(completer: new ValueCompleter('none'), empty: true)
    .addSub(completer: new MultiCompleter(completer: (new ValueCompleter 'crop|cross'), limit: 2, empty: true), empty: true)
  completions['text-decoration'] = new AnyCompleter()
    .addSub(completer: new MultiCompleter(completer: (new ValueCompleter 'underline|overline|line-through|blink'), limit: 4, empty: true), empty: true)
    .addSub(completer: new ValueCompleter('none|inherit'), empty: true)

  borderCompleter = new MultiCompleter()
    .addSub(completer: completions['border-style'], limit:1)
    .addSub(completer: completions['border-width'], limit:1)
    .addSub(completer: colorCompleter, limit:1)
  borderCompleter.findCompleter = (active) ->
    completer = MultiCompleter::findCompleter.call borderCompleter, active
    if completer.subs.length == 3
      sub = _.find completer.subs, (sub) -> sub.completer == completions['border-width']
      sub?.empty = true
    else if completer.subs.length == 2
      sub = _.find completer.subs, (sub) -> sub.completer == completions['border-style']
      sub?.empty = true
    completer
    

  completions['border'] = completions['border-top'] = completions['border-right'] = completions['border-bottom'] = completions['border-left'] = borderCompleter

  completions['opacity'] = completions['orphans'] = new ValueCompleter('inherit', false)

  completions['border-radius'] = new MultiCompleter().addSub completer:unitCompleter, limit: 8
  completions['border-top-left-radius'] = completions['border-top-right-radius'] = completions['border-bottom-left-radius'] = completions['border-bottom-right-radius'] = new MultiCompleter().addSub completer:unitCompleter, limit: 2

  completions['background-attachment'] = makeArrayCompleterSingle(new ValueCompleter 'scroll|fixed|local')
  completions['background-image'] = makeArrayCompleterSingle(imageCompleter)
  bgRepeatCompleter = new ValueCompleter 'repeat|repeat-x|repeat-y|no-repeat|space|round'
  completions['background-repeat'] = makeArrayCompleterSingle(bgRepeatCompleter)
  completions['background-clip'] = completions['background-origin'] = makeArrayCompleterSingle(completions['box-sizing'])
  completions['background-size'] = new AnyCompleter(new MultiCompleter().addSub(completer: unitCompleterAuto, limit: 2), new ValueCompleter 'contain|cover')
  completions['background-size'].findCompleters = (value) ->
    return null if value.match /\b(contain|cover)\b/
    @subs
  bgPositionXCompleter = new AnyCompleter(unitCompleter, completer: new ValueCompleter('left|center|right'), empty: true)
  bgPositionYCompleter = new AnyCompleter(unitCompleter, completer: new ValueCompleter('top|center|bottom'), empty: true)
  bg_pos_compl = new MultiCompleter()
  bg_pos_compl.findCompleter = (active) ->
    return null unless active.txt?
    index = 0
    for part, i in active.parts
      break if i == active.i
      index++ if part.length
    if index == 0
      bgPositionXCompleter
    else if index == 1
      bgPositionYCompleter
    else
      null
  completions['background-position'] = makeArrayCompleter(bg_pos_compl)

  shadow_compl = new MultiCompleter()
    .addSub(completer: unitCompleter, limit: 4)
    .addSub(completer: new ValueCompleter('inset'), limit: 1)
    .addSub(completer: colorCompleter, limit: 1)

  completions['box-shadow'] = new AnyCompleter(makeArrayCompleter(shadow_compl), new ValueCompleter 'none')

  class BgLayerCompleter extends MultiCompleter
    constructor: (@final=false) ->
      super()
      if @final
        @addSub completer: colorCompleter, limit: 1
      @addSub completer: imageCompleter, limit: 1, empty: true
      @addSub completer: bgRepeatCompleter, limit: 1
      @addSub completer: bgPositionXCompleter, limit: 1
      @addSub completer: bgPositionYCompleter, limit: 1
      @addSub completer: completions['background-size'], limit: 1
      @addSub completer: completions['box-sizing'], limit: 1

  class BgCompleter extends MultiCompleter
    constructor: ->
      super()
      @setSeparator ','
      @layerCompleter = new BgLayerCompleter()
      @finalLayerCompleter = new BgLayerCompleter true

    findCompleter: (active) ->
      if active.i == active.parts.length - 1 then @finalLayerCompleter else @layerCompleter

  completions['background'] = new BgCompleter()


  completions['font-family'] = makeArrayCompleter fontFamilyCompleter
  fontCompleter = new MultiCompleter().setSeparator(',')
  fontCompleter.findCompleter = (active) ->
    index = 0
    for part,i in active.parts
      break if i == active.i
      index++ if part.length

    if index == 0
      new MultiCompleter()
        .addSub(completer: completions['font-style'] , limit: 1)
        .addSub(completer: completions['font-weight'] , limit: 1)
        .addSub(completer: completions['font-variant'] , limit: 1)
        .addSub(completer: completions['font-size'] , limit: 1)
        .addSub(completer: completions['line-height'] , limit: 1)
        .addSub(completer: fontFamilyCompleter, limit: 1)
    else
      fontFamilyCompleter
  completions['font'] = fontCompleter
  
  baseCompleter = new BaseCompleter
  baseListCompleter = new ListCompleter baseCompleter
  transitionTimingCompleter = new AnyCompleter()
    .addSub(completer: new ValueCompleter('ease|linear|ease-in|ease-out|ease-in-out'), empty: true)
    .addSub(completer: (new FunctionCompleter [
      (name:'cubic-bezier', completer: baseListCompleter)]), empty: true)
  completions['transition-timing-function'] = makeArrayCompleterSingle transitionTimingCompleter
  transitionTimeCompleter = new UnitCompleter 's,2|ms'
  completions['transition-duration'] = completions['transition-delay'] = makeArrayCompleterSingle transitionTimeCompleter
  transitionPropertyCompleter = new ValueCompleter 'all,3|background-color|background-image|background-position|border-bottom-color|border-bottom-width|border-color|border-left-color|border-left-width|border-right-color|border-right-width|border-spacing|border-top-color|border-top-width|border-width|bottom|color|crop|font-size|font-weight|height|left|letter-spacing|line-height|margin-bottom|margin-left|margin-right|margin-top|max-height|max-width|min-height|min-width|opacity|outline-color|outline-offset|outline-width|padding-bottom|padding-left|padding-right|padding-top|right|text-indent|text-shadow|top|transform|vertical-align|visibility|width|word-spacing|z-index|zoom'
  completions['transition-property'] = makeArrayCompleterSingle transitionPropertyCompleter
  transitionCompleter = new MultiCompleter()
    .addSub(completer: transitionPropertyCompleter, limit: 1, empty: true)
    .addSub(completer: transitionTimeCompleter, limit: 2)
    .addSub(completer: transitionTimingCompleter, limit: 1)
  completions['transition'] = makeArrayCompleter transitionCompleter
  
  completions['transform-style'] = new ValueCompleter 'preserve-3d|flat'
  angleCompleter = new UnitCompleter 'deg,2|rad'
  angleListCompleter = new ListCompleter angleCompleter
  unitListCompleter = new ListCompleter unitCompleter
  transformFuncCompleter = new FunctionCompleter [
    (name: 'matrix', completer: baseListCompleter)
    (name: 'matrix3d', completer: baseListCompleter)
    (name: 'scale', completer: baseListCompleter)
    (name: 'scale3d', completer: baseListCompleter)
    (name: 'scaleX', completer: baseCompleter)
    (name: 'scaleY', completer: baseCompleter)
    (name: 'scaleZ', completer: baseCompleter)
    (name: 'perspective', completer: baseListCompleter)
    (name: 'rotate', completer: angleCompleter)
    (name: 'rotate3d', completer: baseListCompleter)
    (name: 'rotateX', completer: baseListCompleter)
    (name: 'rotateY', completer: baseListCompleter)
    (name: 'rotateZ', completer: baseListCompleter)
    (name: 'skew', completer: angleListCompleter)
    (name: 'skewX', completer: angleCompleter)
    (name: 'skewY', completer: angleCompleter)
    (name: 'translate', completer: unitListCompleter)
    (name: 'translate3d', completer: unitListCompleter)
    (name: 'translateX', completer: unitCompleter)
    (name: 'translateY', completer: unitCompleter)
    (name: 'translateZ', completer: unitCompleter)    
    ]
  completions['transform'] = new MultiCompleter transformFuncCompleter

  stylusCompletions['box'] = new ValueCompleter 'horizontal|vertical'
  stylusCompletions['fixed'] = stylusCompletions['absolute'] = stylusCompletions['relative'] = new MultiCompleter()
    .addSub(completer: (new ValueCompleter 'top|left|bottom|right'), limit: 2)
    .addSub(completer: unitCompleter, limit: 2)
  stylusCompletions['@extend'] = stylusCompletions['@extends'] = new ExtendedSelectorCompleter()
  
  atRulesCompletions = {}
  mediaCompleter = new ValueCompleter 'all|braille|embossed|handheld|print|projection|screen|speech|tty|tv'
  atRulesCompletions['@media'] = makeArrayCompleterSingle mediaCompleter
  
  nibCompleter = new ValueCompleter 'nib'
  importCompleter = new AnyCompleter()
  importCompleter.findCompleters = (value, format) ->
    [completer: if format == 'stylus' then nibCompleter else baseCompleter] 
  atRulesCompletions['@import'] = importCompleter

  complete = (format, property, value, offset, cb) ->
    property = property.toLowerCase()
    property = property.replace /^-(webkit|moz|ms|o)-/, ''
    if format == 'stylus' && stylusCompletions[property]
      stylusCompletions[property].complete value, offset, format, cb
    else if completions[property]
      completions[property].complete value, offset, format, cb
    else
      cb()

  completeAtRule = (format, rule, value, offset, cb) ->
    if atRulesCompletions[rule]
      atRulesCompletions[rule].complete value, offset, format, cb
    else
      cb()

  module.exports = complete: complete, completeAtRule: completeAtRule
