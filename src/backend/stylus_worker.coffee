stylus = require "stylus"
path = require "path"
fs = require "fs"
{_} = require "underscore"
stylus = require "stylus"
Normalizer = require(require.resolve("stylus") + '/../lib/visitor/normalizer')

process.on "message", (msg) ->
  cb = (response) ->
    process.send
      callbackId: msg.callbackId
      response: response
  
  if msg.task == 'getStylusOutline'
    getStylusOutline msg.options, cb
  else if msg.task == 'renderStylus'
    renderStylus msg.path, msg.data, cb

selectorstring = (node) ->
  return "" unless node.segments.length
  _.reduce node.segments, (s,v) ->
      s+= v.toString()

lastline = 0
res = {}
_parse = (nodes, parent=null, l=0) ->
  parent ?= name : [], child : [], line: l # Newline separators buggy in 1.2.0
  res[l] = 1

  for node in nodes
    line = node.lineno
    name = node.constructor.name

    if name == "Group"
      continue if res[line]
      parent.child.push _parse node.nodes, null, line
    if name == "Selector"
      selector = selectorstring node
      if line < parent.line
        parent.line = line
      parent.name.push "" + selector
      _parse node.block?.nodes, parent
    if name == "Ident"
      continue if res[line]
      parent.child.push name:[node.toString()], line:lastline+1, ident:!node.val?.block
      #res[line] = 1
      
    if line > lastline
      lastline = line

  parent

getStylusOutline = (options, cb) ->
  opt = 
    filename : options.filename
    imports: [path.dirname(require.resolve 'stylus') + '/lib/functions']
    paths: [require("nib").path]
  
  data = options.data.replace(/\s+$/,'\n')
  parser = new stylus.Parser data, opt

  try
    stylus.nodes.filename = opt.filename
    ast = parser.parse()

    lastline = 0
    res = {}
    nodes = _parse ast.nodes
    evaluator = new stylus.Evaluator ast, opt
    ast = evaluator.evaluate()
    normalizer = new Normalizer ast, opt
    ast = normalizer.normalize()
    compiler = new stylus.Compiler ast, opt
    css = compiler.compile()
    cb nodes: nodes, css: if options.getcss then css else null
    ###
    #failed try to parse out idents
    evaluator = new stylus.Evaluator(ast, opt)
    ast = evaluator.evaluate();
    scope = evaluator.currentScope
    for k,v of scope.locals
      console.log k, v
    ###
  catch err
    cb
      nodes:
        err: true
        name: err.name
        message: err.message
        line: err.lineno or parser.lexer.lineno

renderStylus = (path, data, cb) ->
  try
    options = _imports:[]
    stylus(data.replace(/\s+$/,'\n'), options).
      include(require("nib").path).
      set("filename", path).
      render (err, css) -> 
        cb err: err, css: css, imports: options._imports
  catch e
    cb err:true, css:"", imports:[]
    