define (require, exports, module) ->

  class UnionCollection
    constructor: (opt) ->
      @equal = opt.equal if opt.equal
      @combine = opt.combine if opt.combine
      @subtract = opt.substract if opt.subtract
      @reset = opt.reset if opt.reset

      @children = {}
      @items = []

    setItems: (uid, items) ->
      if @children[uid]
        @removeItems uid

      eq = @equal
      for item in items
        parent = _.find @items, (i) -> eq i, item
        if parent
          @combine parent, item
          item.parent = parent
        else
          @items.push item

      @children[uid] = items

    removeItems: (uid) ->
      items = @children[uid]
      i = items.length
      while --i >= 0
        if items[i].parent
          @subtract items[i].parent, items[i]
        else
          @reset items[i]

    combine: (c, c1) ->
      c.count += c1.count
      c

    subtract: (c, c1) ->
      c.count -= c1.count
      c

    reset: (c) ->
      c.count = 0

  class StatsManager
    constructor: ->
      @colors = new UnionCollection
        equal: (c1, c2) -> _.isEqual c1.rgb, c2.rgb
        combine: (c, c1) ->
          c.hex = c1.hex unless c.hex
          c.count += c1.count

      @fonts = new UnionCollection
        equal: (c1, c2) -> c1.name == c2.name

    addStats: (url, stats) ->
      @colors.setItems url, stats.colors
      @fonts.setItems url, stats.fonts

  module.exports = new StatsManager()
