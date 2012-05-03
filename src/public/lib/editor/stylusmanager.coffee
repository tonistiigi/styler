define (require, exports, module) ->
  
  class StylusManager

    constructor: (@tab) ->
      _.bindAll @, "loadOutline", "onStylusOutline"

      @complete = false
      @haschanged = true
      @tab.session.doc.on "change", =>
        @haschanged = true
        setTimeout @loadOutline, 300

      _.defer @loadOutline

    ruleForLine: (lineno) ->
      return -1 unless @outlinelines
      lineno-- while (!@outlinelines[lineno] and lineno>=0)
      lineno

    ruleForSelectorText: (selectorText, index) ->
      i = 0
      for _i, child of @outlinelines
        if selectorText in child.name
          if i == index
            return child.line
          else
            i++
      -1

    rangeForRule: (line) ->
      start = line
      doc = @tab.session.doc
      length = doc.getLength()
      firstindent = lastindent = doc.getLine(line).match(/^\s*/)[0].length

      while true
        row = doc.getLine(line)
        line++
        if row=="" or @outlinelines[line] # Empty or next rule.
          line--
          break
        indent = row.match(/^\s*/)[0].length
        if indent==row.length # back to original indent
          line--
          break
        if indent < lastindent or indent > lastindent and lastindent > firstindent #next indention level
          break
      start:start, end:line

    previousRule: (rule) ->
      true while rule >= 0 and !@outlinelines[rule--]
      rule + 1

    nextRule: (rule) ->
      true while rule <= @tab.session.doc.getLength() and !@outlinelines[++rule]
      rule

    selectorTextForRule: (ruleid) ->
      @outlinelines[ruleid]?.name.join ","

    completionAtPosition: ({row, column}) ->
      doc = @tab.session.doc

      line = doc.getLine row
      firstword = line.match(/\s*(.*?)(:|\s|$)/)?[1]

      forceSelector =  (row <= @firstline? || !line.match /^\s+/)
      if firstword
        if forceSelector || (firstword.match /[\.#&>|]/) || firstword.match /^(div|span|a|p|br|table|tbody|tr|td|th|li|ul|ol)\b/i
          line = doc.getLine row
          
          if line[0] == '@'
            parts = line.split ' '
            if column <= parts[0].length
              return type: 'atrule', rule: parts[0], offset: column
            else
              return type: 'atrulevalue', rule: parts[0], value: line.substr(parts[0].length + 1), offset: column - parts[0].length - 1
          
          selectors = line.split ","
          ident = (line.match /^\s*/)[0].length
          return if ident > column #wrong return

          prefixpart = line.substr 0, column
          pseudomatch = prefixpart.match /:([a-z-]*)$/i
          if pseudomatch && (column > line.length - 1 || line[column + 1]?.match /^\s$/)
            return type: "pseudo", pseudo: pseudomatch[1], offset: pseudomatch[1].length

          c = 0
          for selector in selectors
            c += selector.length + 1
            continue unless c >= column
          column -= c - selector.length - 1

          # parent rule parts
          parent = [""]
          row2 = row
          if ident != 0
            while row2
              row2--
              item = @outlinelines[row2 + 1]
              if item
                line2 = doc.getLine row2
                ident2 = (line2.match /^\s*/)[0].length
                if ident2 < ident
                  parent = item.name
                  break

          return type:"selector", selector:selector, parent: parent, offset:column

        else
          # non selector
          m = line.match(/^(\s*)([^\s:]+)\s*:?\s*/)
          length = m[0].length
          if column < length or (length and column == length and m[0][length-1] != " ")
            if column - m[1].length == m[2].length #last position
              return type:"property", offset:m[2].length, property:m[2]

          else
            value = line.substr m[0].length
            return type:"value", value: value, property: m[2], offset: column - length

      null

    loadOutline: ->
      return if @loading
      if @haschanged
        @haschanged = false
        @loading = true

        app.console.callAPI "GetStylusOutline",
          url: @tab.get "url"
          publish: app.console.isLiveMode()
          data: @tab.session.getValue()
        , @onStylusOutline


    onStylusOutline: (outline) ->
      iserr = !!outline.err
      if iserr
        @tab.set error:outline
      else
        @outline = outline
        @tab.set error:null if (@tab.get "error")

        @outlinelines = {}
        @firstline = null
        @parseOutline @outline

      if !@complete
        @complete = true
        @trigger "loaded"
      @trigger "update"

      @loading = false
      if @haschanged
        setTimeout @loadOutline, 300


    parseOutline: (outline) ->

      for child in outline.child
        names = child.name
        continue if child.ident
        parentnames = outline.name
        parentnames = [""] unless parentnames.length
        n = []
        for n1 in names
          name = n1.replace(/\s+/g, " ").trim().toLowerCase()
          for n2 in parentnames
            if (name.indexOf "&") != -1
              n.push name.replace /&/g, n2
            else
              n.push (n2 + " " + name).trim()
        child.name = n
        @firstline = child.line unless @firstline?
        @outlinelines[child.line] = child
        child.parent = outline
        if child.child
          @parseOutline child
        


  _.extend StylusManager.prototype, Backbone.Events

  module.exports = StylusManager