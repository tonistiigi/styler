# Path to Styler.
host = '';
# Is current client currently active in the console.
isActive = false
# Reference to the opened popup. Used for focus change and postMessage() calls.
popupWindow = null
# Connection socket
socket = null

return if window.__styler_embed

try
  storage = this.sessionStorage
catch err
  storage = this.localStorage

ua =
  isMoz: !!window.navigator.userAgent.match /firefox/i
  isWebkit: !!window.navigator.userAgent.match /webkit/i
  isIE: !+"\v1"
  isMac: !!window.navigator.platform.match /mac/i

util =
  $: (id) -> document.getElementById id

  node: ->
    args = Array::slice.call arguments
    element = document.createElement args.shift()

    attributes = {}
    children = []
    for arg in args
      continue unless arg
      if typeof arg == 'string'
        children.push document.createTextNode arg
      else if arg.nodeType == Node.ELEMENT_NODE
        children.push arg
      else if typeof arg == 'object'
        attributes[k] = v for k, v of arg

    for name, value of attributes
      if name == 'style' and typeof value == 'object'
        util.style element, value
      else
        element.setAttribute name, value

    element.appendChild child for child in children
    element

  style: (element, styles) ->
    element.style[property] = value for property, value of styles

  toggleClass: (element, className, bool) ->
    classes = element.className.split /\s+/
    exists = className in classes
    if bool && !exists
      classes.push className
      element.className = classes.join ' '
    else if !bool and exists
      classes.splice classes.indexOf(className), 1
      element.className = classes.join ' '

  installStyles: (stylesString)->
    # Ported from Google Closure source.
    if ua.isIE
      stylesheet = document.createStyleSheet()
      stylesheet.cssText = stylesString
    else
      head = document.getElementsByTagName('head')[0]
      unless head
        body = document.getElementsByTagName('body')[0]
        head = document.createElement 'head'
        body.parentNode.insertBefore head, body
      styleSheet = document.createElement 'style'
      propToSet = if ua.isWebkit then 'innerText' else 'innerHTML'
      styleSheet[propToSet] = stylesString
      head.appendChild styleSheet

  getMatchedCSSRulesForElements: (elements) ->
    for element in elements
      # https://bugs.webkit.org/show_bug.cgi?id=89240
      if window.getMatchedCSSRules && !ua.isWebkit
        window.getMatchedCSSRules element
      else
        result = []
        for styleSheet in document.styleSheets
          try
            continue unless styleSheet.cssRules
            util._addMatchingRules element, styleSheet, result
        result

  _addMatchingRules: (element, sheet, result, returnMedia) ->
    for cssRule in sheet.cssRules
      if cssRule.cssRules
        util._addMatchingRules element, cssRule, result, returnMedia
        continue
      if util.elementMatchesSelector element, cssRule.selectorText
        if sheet.media?.length
          media = Array::join.call sheet.media, ','
          if returnMedia && media not in result
            result.push media
            continue
          match = matchMedia media
          continue unless match.matches
        unless returnMedia
          result.push cssRule

  getPossibleMediaQueries: (element) ->
    result = []
    for styleSheet in document.styleSheets
      try
        continue unless styleSheet.cssRules
        util._addMatchingRules element, styleSheet, result, true
    result

  elementMatchesSelector: do ->
    d = document.createElement 'div'
    func = d.matchesSelector || d.webkitMatchesSelector || d.mozMatchesSelector || d.msMatchesSelector || -> false
    (el, selector) ->
      try
        func.call el, selector
      catch e
        false

  keys: Object.keys || (obj) -> key for key, val of obj

  # Taken from underscore.coffee source.
  isEqual: (a, b) ->
    return true if a is b

    atype = typeof(a); btype = typeof(b)

    return false if atype isnt btype
    return true if `a == b`
    return false if (!a and b) or (a and !b)
    return a.isEqual(b) if a.isEqual
    #return a.getTime() is b.getTime() if _.isDate(a) and _.isDate(b)
    #return false if _.isNaN(a) and _.isNaN(b)
    return false if atype isnt 'object'
    return false if a.length and (a.length isnt b.length)
    aKeys = util.keys(a); bKeys = util.keys(b)
    return false if aKeys.length isnt bKeys.length
    return false for key, val of a when !(key of b) or !util.isEqual(val, b[key])
    true

  ruleSpecificy: (rule) ->
    # <http://www.w3.org/TR/CSS2/cascade.html#specificity>
    sp1 = sp2 = sp3 = 0
    rule = rule.replace /::[a-z-]+|:(after|before|first-letter|first-line)/ig, ->
      sp3++
      ''
    rule = rule.replace /:[a-z-]+(\(.*\))?|\[.*\]|\.[a-z][\w-]+/ig, ->
      sp2++
      ''
    rule = rule.replace /#[a-z][\w-]+/ig, ->
      sp1++
      ''
    sp3 += rule.match(/[a-z]+/ig)?.length || 0
    sp1 * 1e6 + sp2 * 1e3 + sp3



getSessionId = (newvalue=null) ->
  sessionId = storage.getItem '_styler_session_id'
  sessionId = ~~ (Math.random() * 1e8) unless sessionId
  sessionId = newvalue if newvalue
  storage.setItem '_styler_session_id', sessionId
  sessionId

isSupportedAgent = ->
  return true if window.navigator.userAgent.match /webkit/i
  match = window.navigator.userAgent.match /firefox\/([0-9]+)/i
  if match && parseInt(match[1], 10) >= 8 then true else false

_matchMediaListeners = {}
setupMatchMediaListeners = (elementId) ->
  element = elements[elementId]
  return unless element
  mediaQueries = util.getPossibleMediaQueries element
  newListeners = {}
  for query in mediaQueries when !_matchMediaListeners[query]
    match = matchMedia query
    newListeners[query] = match
    match.addListener _mediaChangeListener
  for query, match of _matchMediaListeners when query not in mediaQueries
    match.removeListener _mediaChangeListener
    delete _matchMediaListeners[query]
  for query, match of newListeners
    _matchMediaListeners[query] = match

_mediaChangeListener = ->
  if lastStyledElement != null
    styles = getStyles elements[lastStyledElement]
    lastStyledElementJson = JSON.stringify styles
    sendMessage? 'change:styles', id: lastStyledElement, styles: styles.result, nearby: styles.nearby


# # Keyboard commands

keyboardCommands = {}
keyMatchesCommand = (e, cmd) ->
  conf = keyboardCommands[cmd]
  return false unless conf
  conf = if ua.isMac then conf.mac else if conf.win then conf.win else conf.mac
  return false if conf.code != e.keyCode
  return false if conf.meta && not e.metaKey
  return false if conf.shift && not e.shiftKey
  return false if conf.ctrl && not e.ctrlKey
  return false if conf.alt && not e.altKey
  e.stopPropagation()
  e.preventDefault()
  true

keyboardCommandText = (cmd) ->
  conf = keyboardCommands[cmd]
  return false unless conf
  if ua.isMac then conf.mac.txt else conf.win.txt

onKeyDown = (e) ->
  if keyMatchesCommand e, 'toggle-window-mode'
    openConsole()
  else if isActive && keyMatchesCommand e, 'toggle-iframe-container'
    tryToggleHideIframe()
  else if isActive && keyMatchesCommand e, 'start-inspector-mode'
    startInspector (id) -> sendMessage 'inspect', id: id
  else if isInspecting
    switch e.keyCode
      when 27 then stopInspector() # Esc.
      when 40 then inspectorResult.moveDown() # Down.
      when 38 then inspectorResult.moveUp() # Up.
      when 13 then onInspectorSelect(e) # Enter.
    e.stopPropagation()
    e.preventDefault()

baseURL = ''

init = (h) ->
  host = h
  start = -> setTimeout (-> loadSocketIO ->
    _fixPrototypeJSON()

    if window.__styler_bookmarklet
      return startEmbedMode()

    socket = io.connect "http://#{host}/clients"

    stylesheets = []
    socket.on 'connect', ->
      stylesheets = getStyleSheets()
      socket.emit 'register',
        useragent: window.navigator.userAgent
        name: document.title
        sessionId: getSessionId()
        url: window.location.href
        css: stylesheets
        embed: (ua.isMoz || ua.isWebkit) && !window.navigator.platform.match /mobile/i

      # Update new style sheets if they are programmatically added.
      setInterval ->
        newSheets = (sheet for sheet in getStyleSheets() when sheet not in stylesheets)
        return unless newSheets.length
        socket.emit 'change:stylesheets', newSheets
        stylesheets = stylesheets.concat newSheets
      , 2000
    socket.on 'error', ->
      if /chrome/i.test(window.navigator.userAgent) && window.location.protocol == 'file:' && /^win/i.test(window.navigator.platform)
        alert 'Chrome sandbox prevents connecting to other pages from pages using file:// protocol. Open Chrome with argument --allow-file-access-from-files to bypass this check.'
    socket.on 'registered', (id, sessionId, keys) ->
      getSessionId sessionId
      keyboardCommands = keys
      # Add ID to the title so extensions can use it for focus switching.
      oldTitle = document.title.replace /\s?\(\d+\)$/, ''
      document.title = oldTitle + " (#{id})"
      onConnected()

    socket.on 'callclient', (name, data, cb) ->
      publicAPI[name]? data, cb

    socket.on 'baseurl', (value) ->
      baseURL = value

    socket.on 'disconnect', ->
      document.title = document.title.replace /\s\(\d+\)$/, ''

  ), 500

  if document.readyState in ['complete', 'interactive']
    start()
  else
    document.addEventListener 'DOMContentLoaded', -> start()

# PrototypeJS 1.6 breaks JSONize of arrays.
# Don't rely on this hack and upgrade to 1.7+.
_fixPrototypeJSON = ->
  encodePacket = io.parser.encodePacket
  io.parser.encodePacket = ->
    array_toJSON = Array::toJSON
    Array::toJSON = null if array_toJSON
    result = encodePacket arguments...
    Array::toJSON = array_toJSON
    result

loadSocketIO = (cb) ->
  return cb() if window.io && window.io.connect
  script = util.node 'script',
    type: 'text/javascript'
    src: "http://#{host}/socket.io/socket.io.js"
  script.onload = -> cb()
  # Todo: Retry on errors
  (document.getElementsByTagName('head')[0] || document.body).appendChild script

onConnected = ->
  createInspectorElements()
  util.installStyles STYLER_CSS

  window.addEventListener 'message', onPostMessage, false

  setTimeout dispatchLoadedEvent, 100

  # Low-priority rescan after every 10 seconds.
  setInterval ->
    if isActive
      scanTree (results) ->
        sendMessage 'change:dom', tree: results
      , true, false
  , 1e4

  window.addEventListener 'keydown', onKeyDown, true

  unload_time = (new Date).setTime parseInt(storage.getItem('_styler_unload_time'))
  load_diff = (new Date) - unload_time
  mode = storage.getItem('_styler_mode')
  if mode == 'iframe' && load_diff < 2000
    openConsole 'iframe'
  else
    showMessage 'Press <span>' + keyboardCommandText('toggle-window-mode') + '</span> to launch Styler.'

onPostMessage = (e) ->
  origin = "http://#{host}"
  return unless 0 == e.origin.indexOf origin
  {name, param, callbackId} = e.data
  publicAPI[name]? param, (resp) ->
    data = name: 'messageResponse', callbackId: callbackId, data: resp
    popupWindow = e.source
    e.source.postMessage data, origin

sendMessage = (name, params) ->
  return unless isActive and socket
  socket.emit 'clientmessage', name, params

getStyleSheets = ->
  for sheet in document.styleSheets
    continue unless url = sheet.href or sheet.ownerNode?.getAttribute 'data-url'
    continue if url.match /^data/i
    url


# # Public API. All these methods can be called by console/backend.
lastStyledElement = null
lastStyledElementJson = ''

publicAPI =
  identify: (params, cb) ->
    showMessage params.msg

  getSessionId: (params, cb) ->
    cb sessionId: getSessionId()

  toggleApplicationMode: (params, cb) ->
    toggleApplicationMode(cb)

  getLastStyledElement: (params, cb) ->
    cb lastStyledElement: lastStyledElement

  getStyles: (params, cb) ->
    lastStyledElement = params.id
    styles = getStyles elements[params.id]
    lastStyledElementJson = JSON.stringify styles
    cb styles: styles.result, nearby: styles.nearby
    setTimeout ->
      setupMatchMediaListeners lastStyledElement
    , 1

  toggleIframe: (params, cb) ->
    tryToggleHideIframe() if isActive

  getDOMTree: (params, cb) ->
    scanTree (results) -> cb tree: results

  startInspector: (params, cb) ->
    startInspector (id) -> cb id: id

  showInspectArea: (params, cb) ->
    highlightElementArea elements[params.id], true
    cb()

  serializeElement: (param, cb) ->
    element = elements[param.id]
    cb if element then serializeElement element else null

  setStyles: (param) ->
    setStyleSheetData param.url, param.data
    if lastStyledElement != null
      styles = getStyles elements[lastStyledElement]
      lastStyledElementJson = JSON.stringify styles
      sendMessage? 'change:styles', id: lastStyledElement, styles: styles.result, nearby: styles.nearby
      setTimeout ->
        setupMatchMediaListeners lastStyledElement
      , 1

  unserializeElement: (param, cb) ->
    cb id: unserializeElement param.selector, param.length, param.index

  activate: (param, cb) ->
    isActive = true

    if inspectOnActivation
      setTimeout ->
        if lastRightClickedElement
          sendMessage 'inspect', id: getOutlineId lastRightClickedElement
        inspectOnActivation = false
      , 700
    if _media != 'sheet'
      sendMessage? 'change:media', media: _media

  elementsForSelector: (params, cb) ->
    try
      nodes = document.querySelectorAll params.selector
    catch err
      return cb ids:[]
    cb ids: (id for node in nodes when (id = getOutlineId node) != null)

  setElementPseudo: (params, cb) ->
    el = elements[params.id]
    return unless el
    setElementPseudo el, params.pseudos
    cb()

  clearPseudos: (params, cb) ->
    clearPseudos()
    cb()

  deactivate: ->
    isActive = false
    stopInspector() if isInspecting

  setMedia: (params, cb) ->
    setMedia params.value
    cb()

  findElementMatches: ({selector, parent, offset, after}, cb) ->
    results = {}

    currentsel = ''
    lastpart = selector.match /[\.#\s]([^\.#\s]*)$/
    lastpart = [selector,selector] unless lastpart
    if lastpart[0].length != selector.length
      if selector[0] == '&'
        currentsel = ''
      else
        currentsel = selector.substr 0, selector.length - lastpart[0].length
    else
      currentsel = '*'
    for p,i in parent
      parent[i] += ' ' + currentsel

    query = ''
    query = lastpart[1] if lastpart


    search = 'tag'
    search = 'id' if lastpart[0]?[0] == '#'
    search = 'class' if lastpart[0]?[0] == '.' or lastpart[0]?.length == 0

    for sel in parent
      try
        elements = document.querySelectorAll(sel)
      catch err
        console.log 'catch', sel
        continue

      for element in elements
        if after
          try
            continue unless element.querySelector(after)
          catch err
            continue

        switch search
          when 'tag'
            tag = element.tagName.toLowerCase()
            if (tag.indexOf query) == 0
              results[tag] = 1
          when 'id'
            id = element.id
            continue unless id
            if (id.indexOf query) == 0
              results[id] = 1
          when 'class'
            clazzes = element.classList
            if clazzes
              for clazz in clazzes
                if (clazz.indexOf query) == 0
                  results[clazz] = 1

    pfx = selector.substr 0, selector.length - query.length
    pfx += '.' if lastpart[0]?.length == 0
    cb results: (pfx + result for result of results)

serializeElement = (element) ->
  el = element
  selectors = while el and el not in [document.body, document]
    selector = nameForElement el
    el = el.parentNode
    selector
  # TODO: not all actually required
  selector = selectors.reverse().join ' '
  return null unless selector.length
  queryElements = document.querySelectorAll selector
  return null unless queryElements?.length
  queryElements = Array::slice.call queryElements
  return null if -1 == index = queryElements.indexOf element
  selector:selector, length: queryElements.length, index: index

unserializeElement = (selector, length, index) ->
  queryElements = document.querySelectorAll selector
  if queryElements.length == length # TODO: give some room for error.
    id = getOutlineId queryElements[index]
    return id if id != null
  -1

nameForElement = (el) ->
  name = el.tagName.toLowerCase()
  name += '#' + id if id = el.getAttribute 'id'
  if el.className and typeof el.className == 'string'
    name += '.' + classname for classname in el.className.split ' ' when classname.length && !/^_styler_fake_/.test classname
  name


_treeWalkerFilter = (node) ->
  # Ignore empty text nodes.
  if node.nodeType == Node.TEXT_NODE and !(node.nodeValue.match /\S/)
    NodeFilter.FILTER_REJECT
  # Ignore Javascript and CSS.
  else if node.tagName?.toLowerCase() in ['script', 'style']
    NodeFilter.FILTER_REJECT
  # Ignore Styler elements.
  else if node.id in ['_styler_controls', '_styler_iframe', '_styler_message']
    NodeFilter.FILTER_REJECT
  else
    NodeFilter.FILTER_ACCEPT

elements = []
_treeWalkerFilter.acceptNode = _treeWalkerFilter # Support both object and function.
_scanElements = []
_scanResults = []
_scanResultsCache = []
_scanNode = null
_scanTimeout = 0
_scanBuffer = 0

getOutlineId = (element) ->
  element['_styler_scan' + _scanBuffer]?.id

scanTree = (cb, restart=true, alwaysPublish=true) ->
  if restart
    _scanElements = []
    _scanResults = []
    _scanNode = document.body
    clearTimeout _scanTimeout

  buffer = '_styler_scan' + (if _scanBuffer then 0 else 1)

  walker = document.createTreeWalker document.body, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, _treeWalkerFilter, false
  walker.currentNode = _scanNode
  i = 0

  while el = walker.nextNode()
    if el.nodeType != Node.TEXT_NODE
      el[buffer] = item = n: (nameForElement el), id: _scanElements.length
      _scanElements.push el
    else
      item = el.nodeValue.substring 0, 30
    if el.parentNode[buffer]
      parentItem = el.parentNode[buffer]
      unless parentItem.c
        if el.nodeType == Node.TEXT_NODE and !parentItem.d
          parentItem.d = item
        else
          parentItem.c = []
          if parentItem.d
            parentItem.c.push parentItem.d
            delete parentItem.d
      el.parentNode[buffer].c.push item if parentItem.c
    else
      _scanResults.push item

    # Avoid UI blocking.
    if i++ > (if alwaysPublish then 300 else 100)
      _scanNode = el
      return _scanTimeout = setTimeout (-> scanTree cb, false, alwaysPublish), 10

  unless alwaysPublish
    return if util.isEqual _scanResults, _scanResultsCache

  elements = _scanElements
  _scanBuffer = if _scanBuffer then 0 else 1
  cb _scanResultsCache = _scanResults


# # Elements outline scanning.


# # Style rules capture routines.

_addStyleProp = (style_dec, prop, styles, usedProp, elementIndex) ->
  unless styles[prop]
    value = style_dec.getPropertyValue prop
    return unless value
    current = styles[prop] =
      value: value
      priority: style_dec.getPropertyPriority prop
      index: elementIndex

    previous = usedProp[prop]
    if previous
      if current.priority && !previous.priority && previous.index == current.index
        previous.disabled = true
        usedProp[prop] = current
      else
        current.disabled = true
    else
      usedProp[prop] = current

_getStyleData = (styleDec, usedProp, elementIndex) ->
  styles = {}
  for i in [0...styleDec.length]
    origName = name = styleDec.item i
    # Mozilla hacks for finding shorthands.
    if ua.isMoz
      continue if name.match /(ltr|rtl)-source$/
      name = name.replace /(^-value$)/g, ''
    shorthand = styleDec.getPropertyShorthand? name
    if ua.isMoz and !shorthand and match = name.match /^(padding|margin|font|border|background|text-decoration|overflow)-/
      if styleDec?.getPropertyValue(match[1]) != ''
        shorthand = match[1]
      else if match[1]=='border'
        withnext = name.split('-').slice(0,2).join('-')
        if styleDec?.getPropertyValue(withnext) != ''
          shorthand = withnext
    if shorthand && styleDec?.getPropertyValue shorthand
      unless styles[shorthand]
        _addStyleProp styleDec, shorthand, styles, usedProp, elementIndex
        styles[shorthand].subStyles = {}
      _addStyleProp styleDec, name, styles[shorthand].subStyles, usedProp, elementIndex
    else
      _addStyleProp styleDec, name, styles, usedProp, elementIndex
  styles

inheritProperties = 'color|font|font-family|font-size|font-size-adjust|font-stretch|font-style|font-variant|font-weight|letter-spacing|line-height|list-style|list-style-image|list-style-position|list-style-type|text-align|text-indent|text-transform|visibility|white-space|word-spacing'.split '|'

getBestRule = (element, styles, usedRules) ->
  return null unless id = getOutlineId element
  for {selector, specificy, rule} in getSortedSelectors styles, element, usedRules
    return if specificy >= 1e3
      selector: selector, element: id, file: rule.parentStyleSheet.href || rule.parentStyleSheet.ownerNode?.getAttribute 'data-url'
    else
      null

getSortedSelectors = (styles, element, usedRules) ->
  selectors = []
  pseudoRegExp = /\._styler_fake_(hover|active|visited|focus)/gi
  for i in [styles?.length - 1 ..0]
    rule = styles[i]
    continue if !rule || rule in usedRules
    usedRules.push rule
    parts = rule.selectorText.split ','
    for selector in parts
      selector = selector.trim()
      if util.elementMatchesSelector element, selector
        if pseudoRegExp.test selector
          selector = selector.replace pseudoRegExp, (match, pseudo) -> ':' + pseudo
        selectors.push selector: selector, specificy: (util.ruleSpecificy selector), rule: rule

  selectors.sort (a, b) ->
    if a.specificy == b.specificy then 0 else if a.specificy < b.specificy then 1 else -1

getStyles = (element) ->
  result = []
  nearby = []
  usedProperties = {}

  el = element
  return result:[], nearby:[] unless el
  els = (el while el = el.parentNode)
  els.unshift element
  if element
    result.push
      type: 'element'
      styles: _getStyleData element.style, usedProperties

    usedRules = []
    explicitInherit = []

    #console.log 'elements', elements, elementRules
    for styles, index in util.getMatchedCSSRulesForElements els, ''
      for {selector, rule} in getSortedSelectors styles, els[index], usedRules
        filteredStyles = {}
        length = 0
        media = []
        if rule.parentStyleSheet?.media
          media = media.concat Array::slice.call rule.parentStyleSheet.media
        if rule.parentRule instanceof CSSMediaRule
          media = media.concat Array::slice.call rule.parentRule.media
        media = rule._orig_media || rule.parentStyleSheet?._orig_media || if media.length then media.join(', ') else null
        for property, value of _getStyleData rule.style, usedProperties, index
          if !index || property in inheritProperties || (index == 1 && property in explicitInherit)
            filteredStyles[property] = value
            length++
        if length > 0
          file = rule.parentStyleSheet.href || rule.parentStyleSheet.ownerNode?.getAttribute 'data-url'
          rule.index++ for rule in result when rule.file == file && rule.selector == selector
          result.push
            type: if index == 0 then 'matched' else 'inherited'
            element: (name: nameForElement(els[index]), id: getOutlineId(els[index]))
            file: file
            selector: selector
            index: 0
            styles: filteredStyles
            media: media
      if index == 0
        explicitInherit = for name, prop of usedProperties
          continue unless prop.value == 'inherit'
          delete usedProperties[name]
          name

    nearEls = (el for el in  [element.parentElement, element.previousElementSibling, element.nextElementSibling, element.firstChild] when el)
    for styles, index in util.getMatchedCSSRulesForElements nearEls, ''
      bestrule = getBestRule nearEls[index], styles, usedRules
      nearby.push bestrule if bestrule

  result: result, nearby: nearby


fakePseudos = []
clearPseudos = ->
  setElementPseudo el, [] for {el} in fakePseudos

setElementPseudo = (element, newClasses) ->
  [fakePseudo] = (fakePseudo for fakePseudo in fakePseudos when fakePseudo.el == element)
  fakePseudos.push fakePseudo = el: element, pseudos: [] unless fakePseudo
  {pseudos} = fakePseudo
  newPseudos = for klass in pseudos
    if klass not in newClasses
      util.toggleClass element, '_styler_fake_' + klass, false
      continue
    klass
  for klass in newClasses when klass not in newPseudos
    newPseudos.push klass
    util.toggleClass element, '_styler_fake_' + klass, true
  fakePseudo.pseudos = newPseudos

# # Inspector.

inspectorControlsElement = null
inspectorAreaElement = null

isInspecting = false
inspectorResult = null
_inspectorCallback = null
_inspectorHideTimeout = 0

createInspectorElements = ->
  el = util.$ '_styler_controls'
  el.parentNode.removeChild el if el
  document.body.appendChild inspectorControlsElement =
    util.node 'div', id: '_styler_controls', class: 'styler-controls styler-reset',
      inspectorAreaElement = util.node 'div', class: 'inspector-area styler-reset'
      (inspectorResult = new InspectorResult).el

highlightElementArea = (element, temporary=false) ->
  return unless element
  box = element.getBoundingClientRect()
  util.style inspectorAreaElement,
    left: box.left + pageXOffset + 'px'
    top: box.top + pageYOffset + 'px'
    width: box.width + 'px'
    height: box.height + 'px'
    display: 'block'

  clearTimeout _inspectorHideTimeout
  _inspectorHideTimeout = setTimeout clearHighlight, 1400 if temporary

clearHighlight = ->
  util.style inspectorAreaElement, left: 0, top: 0, width: 0, height: 0, display: 'none'

startInspector = (cb) ->
  _inspectorCallback = cb
  return if isInspecting
  window.addEventListener 'mousemove', onInspectorMove, true
  window.addEventListener 'click', onInspectorSelect, true
  isInspecting = true
  showMessage 'Inspector mode activated'

stopInspector = ->
  return unless isInspecting
  clearHighlight()
  util.style inspectorResult.el, display: 'none'

  window.removeEventListener 'mousemove', onInspectorMove, true
  window.removeEventListener 'click', onInspectorSelect, true
  isInspecting = false

onInspectorMove = (e) ->
  # Temporarly clear so it doesn't affect results.
  util.style inspectorControlsElement, display: 'none'
  currentElement = document.elementFromPoint e.clientX, e.clientY
  util.style inspectorControlsElement, display: 'block'
  if currentElement
    inspectorResult.setSelection currentElement
    currentElement = inspectorResult.getSelection()
    highlightElementArea currentElement
    if e.clientX > window.innerWidth * .6 && !inspectorResult.onLeft
      util.style inspectorResult.el, display: 'block', right: '', left: '0px'
      inspectorResult.onLeft = true
    else if e.clientX < window.innerWidth * .4 && inspectorResult.onLeft
      util.style inspectorResult.el, display: 'block', right: '0px', left: ''
      inspectorResult.onLeft = false
    else unless inspectorResult.onLeft?
      util.style inspectorResult.el, display: 'block', right: '0px', left: ''
      inspectorResult.onLeft = false


  else
    inspectorResult.clear()
    util.style inspectorInfo.el, display: 'none'
  e.stopPropagation()
  e.preventDefault()

onInspectorSelect = (e) ->
  selection = inspectorResult.getSelection()
  _inspectorCallback? getOutlineId(selection) if selection
  stopInspector()
  popupWindow?.focus()

  e.stopPropagation()
  e.preventDefault()

# InspectorResult view lets user pick parent elements to inspect.
class InspectorResult

  constructor: ->
    @el = util.node 'div', class: 'inspectorResult'
    @clear()

  clear: ->
    @options = []
    @selection = null

  setSelection: (el) ->
    manualSelection = @selection and @options.length and @options[@options.length - 1] != @selection
    @options = []
    while el and el != document.body and el != document.documentElement
      @options.unshift el
      el = el.parentNode

    return @selection = null unless @options.length

    unless manualSelection and @selection in @options
      @selection = @options[@options.length - 1]
    @render()

  getSelection: -> @selection

  moveUp: ->
    return unless @selection
    index = @options.indexOf @selection
    if index > 0
      highlightElementArea @selection = @options[index - 1]
      @render()

  moveDown: ->
    return unless @selection
    index = @options.indexOf @selection
    if index != -1 and index < @options.length - 1
      highlightElementArea @selection = @options[index + 1]
      @render()

  render: ->
    fragment = document.createDocumentFragment()
    for el in @options
      item = util.node 'div', nameForElement el
      util.style item, background: '#ddd' if el == @selection
      fragment.appendChild item
    @el.innerHTML = ''
    @el.appendChild fragment

# # Console launch and mode switch.


getIframeMode = ->
  storage.getItem('_styler_iframe_mode') || 'sidebyside'

setIframeMode = (mode) ->
  storage.setItem '_styler_iframe_mode', mode
  if window.__styler_embed
    util.toggleClass document.body, 'is-sidebyside', mode == 'sidebyside'

toggleIframeMode = ->
  setIframeMode if getIframeMode() == 'sidebyside' then 'hovered' else 'sidebyside'
  renderIframes()

openConsole = (mode) ->
  mode ?= if isActive
    'window'
  else
    storage.getItem '_styler_mode'

  mode = 'window' unless mode
  console.log 'openConsole', mode

  iframe = util.$ '_styler_iframe'
  iframe.parentNode.removeChild iframe if iframe
  if util.$('_styler_embed')
    util.style util.$('_styler_embed'), width: '100%'
  if mode == 'window'
    if isActive && popupWindow && storage.getItem('_styler_mode') == 'window'
      popupWindow.focus()
    else
      try
        popupWindow.close() if popupWindow
      popupWindow = window.open "http://#{host}/#{getSessionId()}", 'styler_console', 'width=990,height=680'
      unless popupWindow
        alert "A popup blocker was detected that is preventing Styler from opening. Please add http://#{host}/ to the list of allowed sites."
  else
    return unless isSupportedAgent()
    if !getEmbedMode()
      startEmbedMode()
      iframeContainer = util.node 'div', id: '_styler_iframe',
        util.node 'iframe', src: "http://#{host}/#{getSessionId()}"
      document.body.appendChild iframeContainer
      renderIframes()
      setIframeMode getIframeMode()
      tryToggleHideIframe true

      detectIframeReload()
      iframeContainer.addEventListener 'mousedown', resizerMouseDown
    else
      getEmbedMode().toggleApplicationMode()
  storage.setItem '_styler_mode', mode

_iframeUnloadListened = false
detectIframeReload = ->
  unless _iframeUnloadListened
    window.addEventListener 'beforeunload', ->
      storage.setItem '_styler_unload_time', new Date().getTime()
  _iframeUnloadListened = true

iframeHidden = parseInt(storage.getItem('_styler_iframe_hidden')) || false

tryToggleHideIframe = (noflip=false) ->
  return embedmode.tryToggleHideIframe(noflip) if embedmode = getEmbedMode()
  iframe = util.$ '_styler_iframe'
  if iframe && !isResizing
    iframeHidden = !iframeHidden unless noflip
    if iframeHidden
      util.style iframe, right: -iframeWidth + 3 + '%', opacity: .4
      if getIframeMode() == 'sidebyside'
        util.style util.$('_styler_embed'), width: '97%'
    else
      renderIframes()
    storage.setItem '_styler_iframe_hidden', if iframeHidden then 1 else 0

isResizing = false
startResizerX = 0
iframeWidth = parseInt(storage.getItem('_styler_iframe_width')) || 40

resizerMouseDown = (e) ->
  return unless e.target.id == '_styler_iframe' && !isResizing
  if iframeHidden
    return tryToggleHideIframe()
  isResizing = true
  util.toggleClass document.body, 'is-resizing', true
  window.addEventListener 'mousemove', resizerMouseMove, true
  window.addEventListener 'mouseup', resizerMouseUp, true
  startResizerX = e.clientX
  e.stopPropagation()
  e.preventDefault()

resizerMouseMove = (e) ->
  delta = (e.clientX - startResizerX)
  startResizerX += delta
  iframeWidth -= delta / window.innerWidth * 100
  renderIframes()
  e.stopPropagation()
  e.preventDefault()

resizerMouseUp = ->
  target = util.$('_styler_iframe')
  util.toggleClass document.body, 'is-resizing', false
  window.removeEventListener 'mousemove', resizerMouseMove, true
  window.removeEventListener 'mouseup', resizerMouseUp, true
  isResizing = false
  storage.setItem '_styler_iframe_width', iframeWidth

renderIframes = ->
  util.style util.$('_styler_iframe'), width: iframeWidth + '%', right: 0, opacity: 1
  if getIframeMode() == 'sidebyside'
    util.style util.$('_styler_embed'), width: (100 - iframeWidth) + '%'
  else
    util.style util.$('_styler_embed'), width: '100%'

# # Updating style sheet rules.

_styleElementsCache = {}

setStyleSheetData = (url, styleData) ->
  el = _styleElementsCache[url]
  unless el
    linkElement = null
    for sheet in document.styleSheets
      if sheet.href == url and sheet.ownerNode
        linkElement = sheet.ownerNode
    if linkElement
      _styleElementsCache[url] = el = util.node 'style', type: 'text/css', 'data-url': url
      if linkElement.getAttribute 'media'
        el.setAttribute 'media', linkElement.getAttribute 'media'
      linkElement.parentNode.insertBefore el, linkElement
      linkElement.parentNode.removeChild linkElement
    else
      console.warn 'No stylesheet #{url} found'

  return unless el

  # Correct URLs where needed.
  relative = _relativeURL (window.location.href), url
  if relative
    styleData = styleData.replace /(url\s*\(\s*['"]?(?!['"]|\/|https?:|data:))/ig, "$1" + relative
  else if relative == null
    parts = url.split '/'
    parts.pop()
    origin = parts.slice(0,3).join '/'
    styleData = styleData.replace /(url\s*\(\s*['"]?(?!['"]|\/|https?:|data:))/ig, "$1" + (parts.join '/') + '/'
    styleData = styleData.replace /(url\s*\(\s*['"]?(?=\/))/ig, "$1" + origin

  el.innerHTML = styleData
  sheet = el.sheet
  unless el.lastSheet == sheet
    replacePseudos sheet
    replaceMedia sheet unless _media == 'sheet'
  el.lastSheet = sheet

# Add fake classnames for pseudo classes in shylesheet or media rule.
replacePseudos = (sheet) ->
  pseudoRegExp = /:(hover|visited|focus|active)/i
  pseudoRegExp2 = /:(hover|visited|focus|active)/ig

  for rule, index in sheet.cssRules
    {selectorText} = rule
    if rule.cssRules
      replacePseudos rule
      continue
    if pseudoRegExp.test selectorText
      selectors = selectorText.split ','
      newParts = []
      for selector in selectors
        newParts.push selector
        if pseudoRegExp.test selector
          newParts.push selector.replace pseudoRegExp2, (match, klass) -> '._styler_fake_' + klass
      if !ua.isMoz
        rule.selectorText = newParts.join ','
      else
        ruleTxt = rule.cssText.replace /^.*(?={)/, newParts.join ','
        sheet.deleteRule index
        sheet.insertRule ruleTxt, index

_media = 'sheet'
setMedia = (media) ->
  if _media != media
    _media = media
    replaceMedia sheet for sheet in document.styleSheets

replaceMedia = (sheet) ->
  if sheet.media
    media = sheet.media.mediaText
    if _media == 'screen'
      sheet.media.mediaText = sheet._orig_media if sheet._orig_media
    else
      value = media.replace /screen/, 'none', 'g' if _media == 'print'
      value = media.replace _media, 'screen', 'g'
      sheet.media.mediaText = value
      sheet._orig_media = media

  try
    if sheet.cssRules
      for rule, index in sheet.cssRules
        if rule instanceof CSSMediaRule
          media = rule.media.mediaText
          if _media == 'screen'
            if rule._orig_media
              rule.media.mediaText = rule._orig_media
          else
            value = media.replace /screen/, 'none', 'g' if _media == 'print'
            value = media.replace _media, 'screen', 'g'
            rule.media.mediaText = value
            rule._orig_media = media
          continue

# Return relative path from two URLs.
# Based on <http://github.com/joyent/node/tree/master/lib/path.js>
_relativeURL = (from, to) ->
  fromParts = from.split '/'
  toParts = to.split '/'
  return null if fromParts[2] != toParts[2] # Origins don't match.

  fromParts.pop()
  toParts.pop()

  length = samePartsLength = Math.min fromParts.length, toParts.length
  for i in [2...length]
    if fromParts[i] != toParts[i]
      samePartsLength = i
      break

  outputParts = ('..' for i in [samePartsLength...fromParts.length])
  outputParts = outputParts.concat (toParts.slice samePartsLength), ['']
  outputParts.join '/'


# # Info messages

showMessage = (msg) ->
  document.body.appendChild div =
    util.node 'div', id: '_styler_message', class: '_styler_message',
      innerDiv = util.node 'div'
  innerDiv.innerHTML = msg
  setTimeout (-> div.className += ' visible'), 1
  setTimeout (-> div.className += ' hidden'), 3000
  setTimeout (-> document.body.removeChild div), 5000

# # Extension helpers

# Provide communication between script and extension via DOM events.

# Reference to the element that was last right clicked on
# to get the element that started context menu.
lastRightClickedElement = null

# If true then lastRightClicked element will be inspected when client is activated.
inspectOnActivation = false

_dispatch = (name, data) ->
  event = document.createEvent 'CustomEvent'
  return unless event
  event.initCustomEvent name, true, true, data
  document.dispatchEvent event

dispatchLoadedEvent = ->
  scripts = document.getElementsByTagName 'script'
  _dispatch 'stylerload', getSessionId()
  document.addEventListener 'stylerinspect', (e) ->
    if isActive
      if lastRightClickedElement
        id = getOutlineId lastRightClickedElement
        sendMessage 'inspect', id: id
        _dispatch 'requestfocuschange', getSessionId()
    else
      _dispatch 'activatefrominspector', getSessionId()
      if lastRightClickedElement
        inspectOnActivation = true

  document.addEventListener 'mousedown', (e) ->
    lastRightClickedElement = e.target if e.button == 2 && e.target
  , true

  for script in scripts
    if script.getAttribute('src') && -1 != script.getAttribute('src').indexOf '/styler.js'
      script.setAttribute 'data-session-id', getSessionId()


makeURLUnique = (url) ->
  parts1 = url.split '#'
  parts2 = parts1[0].split '?'
  if parts2.length > 1
    parts2[1] += '&_styler_embed=1'
  else
    parts2[0] += '?_styler_embed=1'
  parts1[0] = parts2.join '?'
  parts1.join '#'

toggleApplicationMode = (cb) ->
  if getEmbedMode()
    getEmbedMode().toggleApplicationMode cb
  else
    if util.$ '_styler_iframe'
      openConsole 'window'
    else if isSupportedAgent()
      openConsole 'iframe'
      cb?() # No callback if not supported. Callback closes window.

getEmbedMode = ->
  window.parent?.__styler_embed if window.parent != window

embed = null
startEmbedMode = ->
  return if window.__styler_embed
  scripts = document.getElementsByTagName 'script'
  loadScript = url for script in scripts when (url = script.getAttribute('src'))?.match /styler\.js$/
  socket?.disconnect()
  if ua.isMoz
    head = document.getElementsByTagName('head')[0]
    for i in [head.children.length-1 ..0]
      child = head.children[i]
      unless child.tagName == 'script' && child.getAttribute('src')?.match /styler\.js$/
        head.removeChild(child)
    for i in [document.body.children.length-1 ..0]
      child = document.body.children[i]
      unless child.tagName == 'script' && child.getAttribute('src')?.match /styler\.js$/
        document.body.removeChild(child)
  else
    document.write '<body></body>'

  window.addEventListener 'message', (e) ->
    if e.data == 'close-iframe'
      iframe = util.$('_styler_iframe')
      iframe.parentNode.removeChild iframe if iframe
      util.style util.$('_styler_embed'), width: '100%'
    else if e.data == 'getEmbedMode'
      e.source.postMessage embedInfo: true, iframeMode: getIframeMode(), baseURL: baseURL, '*'
    else if e.data == 'toggleIframeMode'
      toggleIframeMode()
      e.source.postMessage embedInfo: true, iframeMode: getIframeMode(), '*'
  , false

  util.installStyles STYLER_CSS
  timeoutIndex = setTimeout (->), 1e6
  clearTimeout i for i in [0..timeoutIndex]
  document.body.style.cssText = 'margin:0;height:100%'
  document.body.parentNode.style.cssText = 'margin:0;height:100%'
  embed = util.node 'iframe', id:'_styler_embed', src: makeURLUnique(window.location.href)
  document.body.appendChild embed

  window.__styler_embed =
    tryToggleHideIframe: tryToggleHideIframe
    toggleApplicationMode: toggleApplicationMode

  embed.addEventListener 'load', ->
    try
      url = embed.contentWindow.location.href.replace /[\?&]_styler_embed=1/, ''
    catch e
      console.log e
    if 0 == url.indexOf baseURL
      scripts = embed.contentDocument.getElementsByTagName 'script'
      hasScript = scripturl for script in scripts when (scripturl = script.getAttribute('src'))?.match /styler\.js$/
      if !hasScript
        script = util.node 'script', src: loadScript, 'type': 'text/javascript'
        embed.contentDocument.body.appendChild script
      history.replaceState {}, embed.contentDocument.title, url


STYLER_CSS = """
._styler_message {
  position: fixed;
  bottom: 0px;
  right: -100px;
  opacity: 0;
  z-index: 10000;
  -webkit-transition: opacity 1s, right 1.5s;
  -moz-transition: opacity 1s, right 1.5s;
}
._styler_message div {
  padding: 5px;
  text-align: center;
  font-family: Helvetica;
  font-size: 13px;
  line-height: 120%;
  border-left: 10px solid #185ABA;
  background: #237bff;
  color: #fff;
}
._styler_message div span {
  font-weight: bold;
}
._styler_message.visible{
  opacity: 1;
  right: 0px;
}
._styler_message.hidden {
  opacity: 0;
  right: -100px;
}
#_styler_iframe {
  position: fixed;
  height: 96%;
  right: 10px;
  top: 2%;
  opacity: 1;
  z-index: 100000;
  -webkit-transition: right .5s, opacity .5s, height .5s, top .5s;
  -moz-transition: right .5s, opacity .5s, height .5s;
  border-left: 6px solid rgba(255,255,255,0);
  cursor: ew-resize;
}
#_styler_iframe iframe {
  cursor: default;
  border: none;
  background: #fff;
  width: 100%;
  height: 100%;
}
body.is-resizing iframe {
  pointer-events: none;
}
.inspectorResult {
  width:200px;
  border: 1px solid #999;
  padding: 5px;
  position:fixed;
  top:0px;
  right:0px;
  display:none;
  background: #fff;
  z-index: 2147483646;
  font-family: Arial;
  color: #000;
  font-size: 13px;
  line-height 150%;
}
.styler-reset {
  overflow:visible;
  position:absolute;
  left:0px;
  top:0px;
  -webkit-box-sizing:border-box;
  box-sizing:border-box;
  width:0px;
  height:0px;
  z-index: 2147483646;
}
.styler-controls .inspector-area {
  border: 1px solid #c00;
  background: rgba(150,150,240,.3);
  display: none;
}
#_styler_embed {
  width: 100%;
  height: 100%;
  margin: 0;
  border: 0;
  -webkit-transition: width .5s;
  -moz-transition: width .5s;
}
.is-sidebyside #_styler_iframe {
  top: 0px;
  height: 100%;
  right: 0px;
}
.is-resizing #_styler_embed {
  -webkit-transition: none;
  -moz-transition: none;
}
"""

this.styler = init: init
