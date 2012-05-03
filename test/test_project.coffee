project = require ".."

module.exports =
  "true is ok": (test) ->
    test.ok true
    test.done()
