define (require, exports, module) ->
  # # DOM helpers

  # Creates a DOM element from tagname, attributes and children.
  # Attributes and children are optional.
  # Style attribute can be passed as an object.
  exports.node = ->
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
        _.extend attributes, arg

    for name, value of attributes
      if name == 'style' and typeof value == 'object'
        $(element).css value
      else
        element.setAttribute name, value

    element.appendChild child for child in children
    element

  # Set style values for a DOM element.
  # DEPRECATED: use $().css() instead.
  exports.style = (element, styles) ->
    element.style[property] = value for property, value of styles

  # Return style value for the element. Includes basic prefix support.
  exports.getStyle = (element, property) ->
    st = window.getComputedStyle element
    for prefix in ['', 'Webkit', 'Moz']
      value = st[prefix + property]
      return value if value
      
  exports.swapNodes = (item1, item2) ->
    itemtmp = item1.cloneNode 1
    parent = item1.parentNode
    item2 = parent.replaceChild itemtmp, item2
    parent.replaceChild item2,item1
    parent.replaceChild item1,itemtmp
    
  # # Queues

  # Parallel queue implementation.
  # Iterators run together for every item in the list.
  exports.parallel = (list, iterator, callback) ->
    num = list.length
    iterator item, (-> callback() unless --num) for item in list

  # Sequential queue implementation.
  # Iterators run one after another for every item in the list.
  exports.series = (list, iterator, callback) ->
    callback() unless list.length
    iterator list[0], -> exports.series list[1..], iterator, callback


  # # URL/Path manipulation

  # Return last part of the path (filename).
  exports.basename = (path) ->
    _.last path.split '/'

  # Combines array of urls into they root urls.
  #
  # For example:
  #
  #   * http://example.com/css/index.css
  #   * http://example.com/css/sub/layout.css
  #   * http://google.com/static.css
  #
  # Turns into:
  #
  #   * http://example.com/css/
  #   * http://www.google.com/
  exports.combineURLRoots = (urls) ->
    origins = _.groupBy urls, (url) -> (url.match '^.*?//.*?/')?[0]
    for i, urls of origins
      url = _.reduce urls, (a, b) -> exports.commonPartOfStrings a, b
      [url] = url.match '.*/'
      url

  # Combine and URL and relative path into a new URL
  exports.combineUrl = (baseUrl, url) ->
    unless url.match '^[a-z]{4,5}:\/\/'
      if url[0] == '/'
        url = baseUrl.match(/^.+[:]\/+[^\/]+/)[0] + url
      else
        parts = baseUrl.split '/'
        url = parts[...-1].join('/') + '/' + url
    
    parts = url.split '/'
    domain = parts[0..2]
    path = parts[3..]
    
    # Taken from <https://github.com/joyent/node/blob/master/lib/path.js#L30>
    i = path.length - 1
    up = 0
    while i >= 0
      last = path[i]
      if last == '.'
        path.splice i, 1
      else if last == ".."
        path.splice i, 1
        up++
      else if up
        path.splice i, 1
        up--
      i--

    return null if up

    (domain.concat  path).join '/'


  # # String tokenization

  exports.commonPartOfStrings = (s1, s2) ->
    str = ""
    for i in [0..Math.min s1.length, s2.length]
      if s1[i] == s2[i] then str += s1[i] else return str

  # Split string into parts while preserving quotes and parentheses
  exports.splitToTokens = (str, sep) ->
    parens = 0
    quote = null

    parts = []
    st = i = 0
    while i < str.length
      if str[i] == sep && !quote && !parens
        if i > st
          parts.push [st, str.substr st, i - st]
        st = ++i
        continue
      if !quote
        quote = str[i] if str[i] in '"\''
        parens++ if str[i] == '('
        parens-- if str[i] == ')' && parens > 0
      else if quote && str[i] == quote
        quote = null
      i++
    if i > st
      parts.push [st, str.substr st, i - st]
    parts

  # Split string into parts and return a info object about the part
  # that matches the offset.
  # Returned object properties:
  #
  # * *txt* - String contents of matched part
  # * *offset* - Offset of the matched part
  # * *parts* - All parts, array of strings
  # * *i* - Index for the matched part
  exports.getPart = (txt, sep, offset) ->
    out = txt: '', offset: 0
    raw_parts = exports.splitToTokens txt, sep
    out.parts = _.map raw_parts, ([start, part], i) ->
      if start <= offset <= start + part.length
        _.extend out, txt:part, offset:offset - start, i:i
      part
    # Clear whitspace in the beginning.
    if match = out.txt?.match /^\s+/
      out.txt = out.txt.substr match[0].length
      out.offset -= match[0].length
    out

  # Remove spaces from the end of the string if they appear after offset
  exports.clearEndSpaces = (value, offset) ->
    # FIXME: Should move outside util as there is no general use for it.
    hasPadding = true
    if value.length > offset
      o = offset
      while value.length > o
        if value[o] != ' '
          hasPadding = false
          break
        o++
    else
      hasPadding = false

    if hasPadding then value.substr 0, offset else value

  exports.highlightSelector = (selector) ->
    parts = [
      (regex: /^#[a-zA-Z][a-zA-Z0-9_-]*/, type: 'sel-id')
      (regex: /^\.[a-zA-Z][a-zA-Z0-9_-]*/, type: 'sel-class')
      (regex: /^:+[a-zA-Z][a-zA-Z0-9-]*/, type: 'sel-pseudo')
      (regex: /^\(.+?\)/, type: 'sel-parens')
      (regex: /^\[.+?\]/, type: 'sel-parens')
      (regex: /^\+>/, type: 'sel-symbol')
      (regex: /^,/, type: 'sel-symbol')
      (regex: /^[a-zA-Z]+[0-9]?/, type: 'sel-tag')
    ]
    out = []
    incomplete = ""
    
    while selector.length
      found = false
      for {regex, type} in parts
        if match = selector.match regex
          if incomplete.length
            out.push type: "sel-unknown", txt: incomplete
            incomplete = ""
          out.push type: type, txt: match[0]
          selector = selector.substr match[0].length
          found = true
          break
      continue if found
      incomplete += selector[0]
      selector = selector.substr 1
    
    if incomplete.length
      out.push type: 'sel-unknown', txt: incomplete
      
    el = exports.node 'span', class: 'higlighted-selector'
    _.each out,(part) -> 
      if part.type in ['sel-class', 'sel-id']
        part.txt = part.txt.substr 1
      el.appendChild exports.node 'span', class: (part.type), (part.txt)
    el
  
  exports.makeToggleFocusable = (el) ->
    $(el).bind 'focus', ->
      el._focused = 1
    $(el).bind 'blur', ->
      el._focused = 0
    $(el).bind 'click', ->
      el._focused++
      if el._focused > 2
         $(el).blur()
         el._focused = 0
  
  exports.formatFileSize =  (size) ->
    sizetext = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    return '0B' unless size
    (size/Math.pow(1024,(i=Math.floor(Math.log(size)/Math.log(1024))))).toFixed(if i==0 then 0 else 1) + sizetext[i]
  
  
  # Convert string "rgb(255, 0, 0)" to "#F00"
  exports.rgbToHex = (rgbStr) ->
    match = rgbStr.match /^rgb\((\d+), (\d+), (\d+)\)$/
    return rgbStr unless match
    red = parseInt match[1]
    green = parseInt match[2]
    blue = parseInt match[3]
    rgb = blue | green << 8 | red << 16
    hex = rgb.toString 16
    hex = '0' + hex until hex.length >= 6
    if hex[0] == hex[1] && hex[2] == hex[3] && hex[4] == hex[5]
      hex = hex[0] + hex[2] + hex[4]
    '#' + hex.toUpperCase()
    
  exports.hexToRgb = (hex) ->
    hex = (hex + '').replace(/[(^rgb\()]*?[^a-fA-F0-9,]*/g, '').split(',')
    return [+hex[0], +hex[1], +hex[2]] if hex.length == 3 
    hex += ''
    if hex.length == 3
      hex = hex.split ''
      return [parseInt((hex[0] + hex[0]), 16), parseInt((hex[1] + hex[1]), 16), parseInt((hex[2] + hex[2]), 16)]
    hex = '0' + hex while hex.length < 6
    return [parseInt(hex.substr(0, 2), 16), parseInt(hex.substr(2, 2), 16), parseInt(hex.substr(4, 2), 16)]

  exports