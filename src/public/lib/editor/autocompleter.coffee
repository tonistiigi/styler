define (require, exports, module) ->

  PropertyCompletions = require "lib/propertycompletions"

  completeSelector = (format, selector, parent, offset, cb) ->
    # Complete only if after space or in the end.
    return cb null if selector.length != offset and selector[offset] != " "

    before = selector.substr 0, offset
    parts = selector.split " " # TODO: maybe better to use str.replace(regexp, func)
    selectorBefore = []
    selectorAfter = []
    c = 0
    found = false
    for part in parts
      if found
        selectorAfter.push part
      else
        c += part.length + 1
      if c <= offset
        selectorBefore.push part
      else if !found
        selectorBefore = (selectorBefore.join " ").trim()
        offset -= c - part.length - 1
        found = true
        selector = part
    selectorAfter = (selectorAfter.join " ").trim()

    parentSelectors = []
    for p in parent
      if selectorBefore
        if selectorBefore.indexOf("&") != -1
          parentSelectors.push selectorBefore.replace "&", p
        else
          parentSelectors.push p + " " + selectorBefore
      else
        parentSelectors.push p
    app.console.callClient "findElementMatches", selector: selector, parent: parentSelectors, offset: offset, after: selectorAfter, (resp) -> cb items: (_.map resp.results.sort(), (value) -> value: value), offset: offset

  propertiesBase = "alignment-baseline|background|background-attachment|background-clip|background-color|background-image|background-origin|background-position|background-repeat|background-size|baseline-shift|border|border-color|border-width|border-style|border-bottom|border-bottom-color|border-bottom-left-radius|border-bottom-right-radius|border-bottom-style|border-bottom-width|border-collapse|border-image-outset|border-image-repeat|border-image-slice|border-image-source|border-image-width|border-left|border-left-color|border-left-style|border-left-width|border-radius|border-right|border-right-color|border-right-style|border-right-width|border-spacing|border-top|border-top-color|border-top-left-radius|border-top-right-radius|border-top-style|border-top-width|bottom|box-shadow|box-sizing|caption-side|clear|clip|clip-path|clip-rule|color|color-interpolation|color-interpolation-filters|color-rendering|content|counter-increment|counter-reset|cursor|direction|display|dominant-baseline|empty-cells|fill|fill-opacity|fill-rule|filter|float|flood-color|flood-opacity|font|font-family|font-size|font-size-adjust|font-stretch|font-style|font-variant|font-weight|glyph-orientation-horizontal|glyph-orientation-vertical|height|image-rendering|ime-mode|kerning|left|letter-spacing|lighting-color|line-height|list-style|list-style-image|list-style-position|list-style-type|margin|margin-bottom|margin-left|margin-right|margin-top|marker|marker-end|marker-mid|marker-offset|marker-start|mask|max-height|max-width|min-height|min-width|opacity|orphans|outline-color|outline-offset|outline-style|outline-width|overflow|overflow-x|overflow-y|padding|padding-bottom|padding-left|padding-right|padding-top|page-break-after|page-break-before|page-break-inside|pointer-events|position|quotes|resize|right|ruby-align|ruby-overhang|ruby-position|shape-rendering|speak|stop-color|stop-opacity|stroke|stroke-dasharray|stroke-dashoffset|stroke-linecap|stroke-linejoin|stroke-miterlimit|stroke-opacity|stroke-width|table-layout|text-align|text-anchor|text-decoration|text-indent|text-justify-trim|text-kashida|text-overflow|text-rendering|text-shadow|text-transform|top|unicode-bidi|vector-effect|vertical-align|visibility|white-space|widows|width|word-break|word-spacing|word-wrap|z-index|zoom|marks"
  propertiesBaseMozWebkit = "animation|animation-delay|animation-direction|animation-duration|animation-fill-mode|animation-iteration-count|animation-name|animation-play-state|animation-timing-function|appearance|backface-visibility|border-image|box-align|box-direction|box-flex|box-ordinal-group|box-orient|box-pack|column-count|column-gap|column-rule-color|column-rule-style|column-rule-width|column-width|hyphens|perspective|perspective-origin|transform|transform-origin|transform-style|transition|transition-delay|transition-duration|transition-property|transition-timing-function|user-modify|user-select"
  propertiesBaseWebkit = "background-inline-policy|binding|border-bottom-colors|border-left-colors|border-right-colors|border-top-colors|box-sizing|column-rule|float-edge|font-feature-settings|font-language-override|force-broken-image-icon|image-region|orient|outline-radius|outline-radius-bottomleft|outline-radius-bottomright|outline-radius-topleft|outline-radius-topright|stack-sizing|tab-size|text-blink|text-decoration-color|text-decoration-line|text-decoration-style|user-focus|user-input|window-shadow"
  propertiesBaseMoz = "background-clip|background-composite|background-origin|background-size|border-fit|border-horizontal-spacing|border-vertical-spacing|box-flex-group|box-lines|box-reflect|box-shadow|color-correction|column-break-after|column-break-before|column-break-inside|column-span|dashboard-region|flow-into|font-smoothing|highlight|hyphenate-character|hyphenate-limit-after|hyphenate-limit-before|hyphenate-limit-lines|line-box-contain|line-break|line-clamp|locale|margin-after-collapse|margin-before-collapse|marquee|marquee-direction|marquee-increment|marquee-repetition|marquee-style|mask|mask-attachment|mask-box-image|mask-box-image-outset|mask-box-image-repeat|mask-box-image-slice|mask-box-image-source|mask-box-image-width|mask-clip|mask-composite|mask-image|mask-origin|mask-position|mask-repeat|mask-size|nbsp-mode|region-break-after|region-break-before|region-break-inside|region-overflow|rtl-ordering|svg-shadow|tap-highlight-color|text-combine|text-decorations-in-effect|text-emphasis-color|text-emphasis-position|text-emphasis-style|text-fill-color|text-orientation|text-security|text-stroke-color|text-stroke-width|transform-style|user-drag|writing-mode"
  propertiesBaseMs = "accelerator|background-position-x|background-position-y|behavior|block-progression|filter|ime-mode|interpolation-mode|layout-flow|layout-grid|layout-grid-char|layout-grid-line|layout-grid-mode|layout-grid-type|line-break|overflow-x|overflow-y|scrollbar-3dlight-color|scrollbar-arrow-color|scrollbar-base-color|scrollbar-darkshadow-color|scrollbar-face-color|scrollbar-highlight-color|scrollbar-shadow-color|scrollbar-track-color|text-align-last|text-autospace|text-justify|text-kashida-space|text-overflow|text-size-adjust|text-underline-position|transform-origin-x|transform-origin-y|word-break|word-wrap|writing-mode|zoom"
  propertiesBaseO = "border-image|link|link-source|tab-size|table-baseline|transform|transform-origin|transition|transition-delay|transition-duration|transition-property|transition-timing-function"

  propertiesStylus = "no-wrap?|box-shadow|user-select|column-count|column-gap|column-rule|column-rule-color|column-rule-width|column-rule-style|column-width|background-size|transform|border-image|transition|transition-property|transition-duration|transition-timing-functions|transition-delay|backface-visibility|opacity|whitespace|box-sizing|box-orient|box-flex|box-flex-group|box-align|box-pack|box-direction|animation|animation-name|animation-duration|animation-delay|animation-iteration-count|animation-timing-function|animation-play-state|animation-fill-mode|border-image|hyphens|appearance|border-radius|reset-box-model?|reset-font?|reset-body?|reset-html5?|fixed|absolute|relative|clearfix?|box|@extends"

  properties = propertiesBase.split "|"
  addProperty = (propStr, pfx) ->
    properties.push "-#{pfx}-#{prop}" for prop in propStr.split "|"
  addProperty propertiesBaseMozWebkit, "webkit"
  addProperty propertiesBaseMozWebkit, "moz"
  addProperty propertiesBaseWebkit, "webkit"
  addProperty propertiesBaseMoz, "moz"
  addProperty propertiesBaseMs, "ms"
  addProperty propertiesBaseO, "o"

  propertiesStylus = propertiesStylus.split "|"

  pseudoClasses = ("hover|focus|active|link|visited||lang|first-child|last-child|first-line|first-letter|before|after").split("|")

  completeProperty = (format, property, offset, cb) ->
    property = property.toLowerCase()
    filter = (p) -> p.length >= property.length and p.indexOf(property) == 0
    matches = _.filter properties, filter
    if format
      matches = matches.concat _.filter propertiesStylus, filter
    # ? in the end means property has no value part.
    cb items: (_.map matches.sort(), (m) ->
      if m[m.length-1] == "?"
        value: m.substr 0, m.length - 1
      else
        value: m, property: true
    ), offset: offset

  completePseudo = (pseudo, offset, cb) ->
    pseudo = pseudo.toLowerCase()
    matches = _.filter pseudoClasses, (p) -> p.length >= pseudo.length and p.indexOf(pseudo) == 0
    cb items: (_.map matches, (m) -> value: m), offset: offset

  completeAtRule = (format, rule, offset, cb) ->
    atrules = '@font-face|@import|@media|@keyframes|@charset|@page'.split '|'
    console.log 'stylus', format
    atrules = atrules.concat("@-#{pfx}-keyframes" for pfx in 'webkit|moz|o|ms'.split('|')) unless format != 'css'
    matches = _.filter atrules, (r) -> r.length >= rule.length and r.indexOf(rule) == 0
    cb items: (_.map matches, (m) -> value: m, sfx: ' '), offset: offset
    
  complete = (format, req, cb) ->
    switch req.type
      when "selector"
        completeSelector format, req.selector, req.parent, req.offset, cb
      when "property"
        completeProperty format, req.property, req.offset, cb
      when "value"
        req.value = req.value.replace /[\!;].*$/, ""
        return cb null if req.offset > req.value.length
        PropertyCompletions.complete format, req.property, req.value, req.offset, cb
      when "pseudo"
        completePseudo req.pseudo, req.offset, cb
      when 'atrule'
        completeAtRule format, req.rule, req.offset, cb
      when 'atrulevalue'
        PropertyCompletions.completeAtRule format, req.rule, req.value, req.offset, cb
  
  exports.complete = complete
  exports
