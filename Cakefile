fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'
jade          = require 'jade'
path          = require 'path'
{_}           = require 'underscore'

views_conf =
    './src/templates/project_item.jade'   : './lib/public/lib/templates/project_item.js'
    './src/templates/output_item.jade'    : './lib/public/lib/templates/output_item.js'
    './src/templates/main.jade'           : './lib/public/lib/templates/main.js'
    './src/templates/console.jade'        : './lib/public/lib/templates/console.js'
    './src/templates/new_project.jade'    : './lib/public/lib/templates/new_project.js'
    './src/templates/url_input.jade'      : './lib/public/lib/templates/url_input.js'
    './src/templates/output_switch.jade'  : './lib/public/lib/templates/output_switch.js'
    './src/templates/outline_info.jade'   : './lib/public/lib/templates/outline_info.js'
    './src/templates/editor.jade'         : './lib/public/lib/templates/editor.js'
    './src/templates/file_item.jade'      : './lib/public/lib/templates/file_item.js'
    './src/templates/tab_switch.jade'     : './lib/public/lib/templates/tab_switch.js'
    './src/templates/mode_switch.jade'    : './lib/public/lib/templates/mode_switch.js'
    './src/templates/settings.jade'       : './lib/public/lib/templates/settings.js'
    './src/templates/warning_browser.jade': './lib/public/lib/templates/warning_browser.js'
    './src/templates/warning_disconnect.jade': './lib/public/lib/templates/warning_disconnect.js'
    './src/templates/warning_overload.jade': './lib/public/lib/templates/warning_overload.js'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn './node_modules/.bin/coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

  build_views views_conf, watch
  build_stylus watch

build_views = (conf, watch) ->
  runtime = fs.readFileSync (path.resolve (require.resolve 'jade'), '../runtime.min.js')
  views = ""
  _.each conf, (outfile, infile) ->
    data = jade.compile(fs.readFileSync(infile),compileDebug: false, client:true).toString()
    out = """
      define(function(require, exports, module){
        require("vendor/jade");
        module.exports = #{data};
      });
    """
    fs.writeFileSync outfile, out
    console.log "Compiled #{outfile}"

    if watch
      fs.watchFile infile, (curr, prev) ->
        if curr.mtime.getTime() != prev.mtime.getTime()
          prop = {}
          prop[infile] = outfile
          build_views prop, false

build_stylus = (watch) ->
  options = ['--out', 'lib/public/css/', '--include', 'node_modules/nib/lib', 'src/style']
  options.unshift '-w' if watch
  #console.log 'stylus', options
  stylus = spawn './node_modules/.bin/stylus', options
  stylus.stdout.on 'data', (data) -> print data.toString()
  stylus.stderr.on 'data', (data) -> print data.toString()


task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src/public/lib', (err, contents) ->
    files = ("src/public/lib/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> print data.toString()
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run the test suite', ->
  build ->
    require.paths.unshift __dirname + "/lib"
    {reporters} = require 'nodeunit'
    process.chdir __dirname
    reporters.default.run ['test']

task 'jade', 'Prebuild views', ->
  build_views views_conf

task 'stylus', 'Build stylus files to css', ->
  build_stylus()


task 'dryice', 'Build compressed modules', ->
  {copy} = require(__dirname + '/support/dryice')
  targetDir = __dirname + '/lib/public/build'

  filter = (input)->
    input = input.replace /vendor\/text!/g, 'text!'
    #input = input.replace /ace\/requirejs\/text!(\.|ace)\//, 'vendor/text_'
    input = input.replace /text!/g, 'text_'
    input = input.replace /ace\/requirejs\/text_(\.|ace)/g, 'text_ace'
    input = input.replace /vendor\/link![^"']+/g, 'empty'
    input
  filters =  [copy.filter.moduleDefines, filter]#, copy.filter.uglifyjs]
  copy({
      source: (root: __dirname + '/lib/public/css', include: /.*\.css$/),
      #filter: [copy.filter.uglifyjs],
      dest: __dirname + '/lib/public/build/styles.css'
  });

  project = copy.createCommonJsProject
      roots: [
          __dirname + '/support/ace/lib'
          __dirname + '/lib/public'
      ]
      ignores: [ 'css/editorview.css' ]
      textPluginPattern: /^(vendor|ace\/requirejs)\/text!/

  ace = copy.createDataObject();
  copy({
      source: (value: 'window.__packaged = true;'),
      dest: ace
  });
  copy({
      source: [__dirname + "/lib/public/vendor/require.js"],
      dest: ace,
      filter: [copy.filter.moduleDefines],
  });
  copy({
      source: (value: 'define("empty");' + (fs.readFileSync (path.resolve (require.resolve 'jade'), '../runtime.min.js')) + ';define("vendor/jade", jade);'),
      dest: ace
  });

  project.ignoredModules = 'vendor/jade': true, 'vendor/link!': true
  copy({
      source: [
        {
              project: (project),
              require: [ 'vendor/underscore',  'vendor/zepto' ,'vendor/backbone', 'lib/backbone-socketio']
        }
      ],
      filter: [copy.filter.moduleDefines],
      dest:  ace
  })
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [  'lib/main_build', 'lib/models', 'lib/router', 'lib/views/app', 'lib/views/warning-screen', 'lib/utils']
        }
      ],
      filter: filters,
      dest:  ace
  })
  copy(source: ace, dest: __dirname + '/lib/public/build/main.js')
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [ 'lib/views/console', 'lib/views/editor' ]
        }
      ],
      filter: filters,
      dest:  __dirname + '/lib/public/build/editor.js'
  })
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [  'lib/editor/autocompleter', 'lib/views/ui/completer', 'lib/views/commandline', 'lib/views/ui/search', 'lib/editor/mousecommands', 'lib/editor/statsmanager' ]
        }
      ],
      filter: filters,
      dest:  __dirname + '/lib/public/build/editor-defer.js'
  })
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [  'lib/views/ui/popup', 'lib/views/ui/imagepreview', 'lib/views/ui/infotip', 'vendor/colorpicker' ]
        }
      ],
      filter: filters,
      dest:  __dirname + '/lib/public/build/editor-optional.js'
  })
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [  'lib/views/newproject', 'lib/views/ui/dirpicker' ]
        }
      ],
      filter: [copy.filter.moduleDefines, filter], # , copy.filter.uglifyjs
      dest:  __dirname + '/lib/public/build/newproject.js'
  })
  project.assumeAllFilesLoaded()
  copy({
      source: [
        {
              project: (project),
              require: [  'lib/views/settings' ]
        }
      ],
      filter: [copy.filter.moduleDefines, filter], # , copy.filter.uglifyjs
      dest:  __dirname + '/lib/public/build/settings.js'
  })

  project.assumeAllFilesLoaded()
  for mode in ['css', 'stylus']
    console.log 'Mode for', mode
    copy({
        source: [
          {
                project: (project),
                require: [ 'lib/editor/' + mode , 'lib/editor/' + mode + 'manager' ]
          }
        ],
        filter:filters,
        dest:   targetDir + "/mode-" + mode + '.js'
    });

  for mode in ['css', 'stylus']
    console.log("worker for " + mode + " mode")
    worker = copy.createDataObject()
    workerProject = copy.createCommonJsProject
        roots: [
            __dirname + '/support/ace/lib'
            __dirname + '/lib/public'
        ]
        #textPluginPattern: /^ace\/requirejs\/text!/

    copy({
        source: [
            {
                project: workerProject,
                require: [
                    'ace/lib/fixoldbrowsers',
                    'ace/lib/event_emitter',
                    'ace/lib/oop',
                    'lib/editor/' + mode + '_worker'
                ]
            }
        ],
        filter: [ copy.filter.moduleDefines ],
        dest: worker
    });
    copy({
        source: [
            __dirname + "/support/ace/lib/ace/worker/worker.js",
            worker
        ],
        dest: targetDir + "/worker-" + mode + ".js"
    });
