define (require, exports, module) ->

  hex2rgba = (hex) ->
    hex = hex.substr 1
    if hex.length == 3
      hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2]
    [ parseInt (hex.substr 0, 2), 16
      parseInt (hex.substr 2, 2), 16
      parseInt (hex.substr 4, 2), 16
      1 ]

  addColor = (out, color) ->
    rgb = color.rgb
    key = rgb.join "_"
    if out[key]
      out[key].count++
    else
      out[key] = count:1, rgb:color.rgb, hex:color.hex

  exports.getStats = (data) ->
    out = colors:{}, fonts:{}

    hexcolors = data.match /(#[0-9a-f]{3}|#[0-9a-f]{6})\b/ig
    if hexcolors
      for hex in hexcolors
        addColor out.colors, hex:hex.toLowerCase(), rgb:hex2rgba hex

    rgbcolors = data.match /rgba?\s*\([0-9\.,\s%]{5,}\)/ig

    if rgbcolors
      for rgbcolor in rgbcolors
        components = rgbcolor.match /[0-9\.\s]+%?/
        if components.length==3 or components.length==4
          color = []
          for component,i in components
            value = parseFloat component.match /[0-9\.]+/
            ispercentage = -1 != component.indexOf "%"
            value *= 2.55 if ispercentage
            color.push if i < 3 then Math.round(value) else value
          if color.length < 4
            color.push 1
          addColor out.colors, rgb:color

    colors = []
    for key, color of out.colors
      colors.push color
    out.colors = colors

    fontregexp = /font-family\s*:\s*.*?(;|\n)/ig
    fontregexp2 = /font-family\s*:\s*(.*?)(;|\n)/i
    fontfamilys = data.match fontregexp
    if fontfamilys
      for fontfamily in fontfamilys
        value = (fontfamily.match fontregexp2)[1]
        continue unless value
        parts = value.split ","
        for part,i in parts
          part = part.trim()
          if part[0] in "'\"" and part[-1..][0] in "'\""
            part = part.substr 1, part.length - 2
          part = part.replace /['"]/g, ""
          continue if part in ["monospace", "serif", "sans-serif", "cursive", "fantasy"] #better not to count generic-family (i think?)
          if out.fonts[part]
            out.fonts[part]++
          else
            out.fonts[part] = 1
    fonts = []
    for name, count of out.fonts
      fonts.push name:name, count:count
    out.fonts = fonts


    out


