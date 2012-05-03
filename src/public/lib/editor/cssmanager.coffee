define (require, exports, module) ->
  {getPart} = require "lib/utils"

  class CSSManager

    constructor: (@tab) ->
      @complete = false
      @tab.session.getMode()._outlineManager = @

      _.bindAll @, "publish", "onPublishComplete"
      @haschanged = true
      @tab.session.doc.on "change", =>
        @haschanged = true
        setTimeout @publish, 1

    publish: ->
      return if @loading
      if @haschanged
        @haschanged = false
        if app.console.isLiveMode()
          @loading = true
          app.console.callAPI "PublishChanges",
            url: @tab.get "url"
            data: @tab.session.getValue()
          , @onPublishComplete

    onPublishComplete: ->
      @loading = false
      setTimeout @loadOutline, 300 if @haschanged

    ruleForLine: (lineno) ->
      lineno-- while (lineno >0 and !@outlinelines[lineno])
      lineno = -1 if lineno == 0 and !@outlinelines[lineno]
      lineno

    ruleForSelectorText: (selectorText, index) ->
      i = 0
      selectorText = selectorText.toLowerCase()
      for _i, child of @outlinelines
        if selectorText in child.selector
          if i == index
            return child.line
          else
            i++
      -1

    rangeForRule: (line) ->
      start = line
      doc = @tab.session.doc
      leftcurly = 0

      while true
        break if line > doc.getLength()
        row = doc.getLine(line - 1).replace /\/\*.*\*\//g, ""

        leftcurly++ if (row.indexOf "{") != -1 #half complete rules
        if leftcurly > 1
          line--
          break
        break if (row.indexOf "}") != -1
        line++

      start:start, end:line

    previousRule: (rule) ->
      true while rule >= 0 and !@outlinelines[--rule]
      rule

    nextRule: (rule) ->
      true while rule <= @tab.session.doc.getLength() and !@outlinelines[++rule]
      rule

    selectorTextForRule: (ruleid) ->
      @outlinelines[ruleid]?.selector.join ","

    completionAtPosition: ({row, column}) ->
      doc = @tab.session.doc

      type = 0

      rr = row
      cc = column
      while !type && rr >= 0

        line = doc.getLine rr
        rbraceindex = line.indexOf "}"
        if rbraceindex != -1 && rbraceindex < cc
          type = 1
        lbraceindex = line.indexOf "{"
        hasbrace = lbraceindex != -1
        if hasbrace
          if lbraceindex < cc
            type = 2
          else
            type = 1
        else if @outlinelines[rr + 1]
          type = 1

        rr--
        cc = 1000
      type =1 if rr < 0
      line = doc.getLine row
      if type == 1
        line = line.replace /\{.*$/, ""

        if line[0] == '@'
          parts = line.split ' '
          if column <= parts[0].length
            return type: 'atrule', rule: parts[0], offset: column
          else
            return type: 'atrulevalue', rule: parts[0], value: line.substr(parts[0].length + 1), offset: column - parts[0].length - 1

        selector = getPart line, ",", column
        return unless selector?.txt?.length

        prefixpart = line.substr 0, column
        pseudomatch = prefixpart.match /:([a-z-]*)$/i
        if pseudomatch && (column > line.length - 1 || line[column + 1]?.match /^\s$/)
          return type: "pseudo", pseudo: pseudomatch[1], offset: pseudomatch[1].length

        return type: "selector", selector: selector.txt, parent: [""], offset: selector.offset

      else
        # non selector
        stmt = getPart line, "{", column
        stmt = getPart stmt.txt, "}", stmt.offset
        stmt = getPart stmt.txt, ";", stmt.offset
        return unless stmt?.txt?.length
        part = getPart stmt.txt, ":", stmt.offset
        return unless part?.txt?

        if part.i == 0
          return null if part.txt.length > part.offset
          return type: "property", offset: part.offset, property: part.txt
        else if part.i == 1
          property = stmt.txt.split(":")[0].trim()
          return type: "value", value: part.txt, property: property, offset: part.offset

      null

    setOutline: (outline) ->
      @outlinelines = {}
      for item in outline
        item.selector = item.selector.split ","
        @outlinelines[item.line] = item

      if !@complete
        @complete = true
        @trigger "loaded"
      @trigger "update"

      #console.log @outlinelines

  _.extend CSSManager.prototype, Backbone.Events

  module.exports = CSSManager