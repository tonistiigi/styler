define (require, exports, module) ->

  {URLInputView, URLInput, URLInputList} = require 'lib/views/ui/urlinput'
  {node, combineURLRoots, parallel} = require 'lib/utils'
  require 'vendor/link!css/newproject.css'

  NewProjectView = Backbone.View.extend
    template: require 'lib/templates/new_project'

    className: 'new-project-view'

    events:
      'submit form.new-project': 'submitForm'
      'click .btn.add-source': 'onAddSourceClick'

    initialize: (opt) ->
      @_initValidations()

      @mode = opt.mode
      @client = opt.client || null
      
      @$el.html @template mode: if @model then 'edit' else 'create'

      @locations = new URLInputList()
      @locations.on 'add', @onLocationAdd, @
      @locations.on 'remove', @onLocationRemove, @

      if @model
        @$('#name').val @model.get 'name'
        @$('#baseurl').val @model.get 'baseurl'
        for file in @model.get 'files'
          file.client = @client
          @locations.add file
      else if @client
        @$('#name').val @client.get 'name'
        url = @client.get 'url'
        url = url.split '/'
        url[url.length - 1] = ''
        @$('#baseurl').val url.join '/'
        
        (@locations.add url: url, client: @client) for url in combineURLRoots @client.get 'css'
      
      @$('#name').on 'change', => @validate 'name'
      @$('#baseurl').on 'change', => @validate 'baseurl'
      
      # TODO: low numbers should appear as words in this message(with i18n).
      if @client
        css = @client.get('css')
        @$('.sources .hint').html if css.length
          "There were #{css.length} stylesheets found on your page " +
            if @locations.size() > 1
              "that appear to come from #{@locations.length} different locations. Please continue by specifying source directories for these locations from your hard drive. If you only need to change files in some of the locations then you can leave the others blank."
            else
              "that all appear to come from the same location. Please continue by specifying a source directory for this location."

        else
          "We didn't find any external stylesheets from the page #{@client?.get('url')}. Styler can only modify styles in external stylesheets. Please move your styles to external stylesheets and try again. You can also add source locations manually by clicking 'Add source location' button."

    # # Validations

    _checkProjectNameEmpty: ->
      !@$('#name').val().length

    _checkBaseURLEmpty: ->
      !@$('#baseurl').val().length

    _checkBaseURLFormat: ->
      !@$('#baseurl').val().match /^\w+:\/\/\/?.+$/

    _checkBaseURLUsed: ->
      url = @$('#baseurl').val()
      project = app.Projects.find (project) =>
        baseURL = project.get 'baseurl'
        (baseURL.indexOf(url) == 0 || url.indexOf(baseURL) == 0) && (!@model || project.id != @model.id)
      if project
        projectname: project.get 'name'
      else
        false

    _checkBaseURLPresent: ->
      return false unless @client
      url = @$('#baseurl').val()
      pageurl = @client.get 'url'
      if pageurl.indexOf(url) == 0
        false
      else
        pageurl: pageurl

    _checkSourceListEmpty: ->
      !@locations.find (l) -> l.get('path').length && l.get('url').length

    _checkSourceListErrors: (cb) ->
      !!@locations.find (location) ->
        location.view.status in ['url_format', 'url_empty', 'path_error'] || (location.view.status == 'ok' && location.get('type') == 'stylus' && !location.view.scan?.stylusoutExists)

    _initValidations: ->
      @validations =
        name: [
          type: 'error'
          msg: 'Project name should not be empty.'
          summary: 'Project name should not be empty.'
          exec: @_checkProjectNameEmpty
        ]
        baseurl: [
          (type: 'error',
          msg: 'Base URL should not be empty.',
          summary: 'Base URL should not be empty.',
          exec: @_checkBaseURLEmpty)

          (type: 'error',
          msg: 'Base URL has wrong format or is too general.',
          summary: 'Base URL is in wrong format.',
          exec: @_checkBaseURLFormat)

          (type: 'error',
          msg: 'This URL matches the base URL for project "{projectname}" and can\'t be used. If you need to use this URL you have to first delete project "{projectname}".',
          summary: 'Base URL is already used.',
          exec: @_checkBaseURLUsed)

          (type: 'warning',
          msg: 'This URL does not match the currently active page URL ({pageurl}). You will not be abled to use this project to modify stylesheets on that page.',
          exec: @_checkBaseURLPresent)
        ]
        sourcelist: [
          (type: 'error',
          summary: 'You have to fill in at least one source location.',
          exec: @_checkSourceListEmpty)

          (type: 'error',
          summary: 'Source locations configuration contains critical errors.',
          exec: @_checkSourceListErrors)
        ]

    validate: (fieldname=null) ->
      hasError = false
      for field in ['name', 'baseurl', 'sourcelist']
        continue if fieldname && field != fieldname

        checks = @validations[field]
        noError = true
        for check in checks
          err = check.exec.call(@)
          if err
            noError = false
            hasError = true if check.type == 'error'
            @showError field, check, err
            break
        @showError field, null if noError
      hasError

    showError: (field, validation, result) ->
      errorsSummaryEl = @$ '.errors-summary'
      errors = errorsSummaryEl.find '.errors'

      errorline = errors.find ".error.#{field}"
      if errorline.size() && (!validation || validation.type == 'warning')
        errorline.remove()
      else if validation && validation.type == 'error'
        unless errorline.size()
          errors.append errorline = node 'div', class: "error #{field}"
          errorline = $(errorline)
        summaryMessage = validation.summary
        summaryMessage = summaryMessage.replace (new RegExp "{#{k}}", 'g'), v for k, v of result
        errorline.html summaryMessage

      errorsSummaryEl.toggleClass 'visible', errors.children().length

      itemEl = @$ ".input-row.#{field}"
      return unless itemEl.size()
      noteEl = itemEl.find '.note'
      itemEl.removeClass 'has-error'
      itemEl.removeClass 'has-warning'

      if validation
        message = validation.msg
        message = message.replace (new RegExp "{#{k}}", 'g'), v for k, v of result
        noteEl.html message
        if validation.type == 'error'
          itemEl.addClass 'has-error'
        else
          itemEl.addClass 'has-warning'

    onAddSourceClick: ->
      @locations.add client: @client, url: 'http://', novalidate: true
      @locations.last().view.$('input.url').get(0).focus()

    onLocationAdd: (location) ->
      view = new URLInputView model: location
      view.on 'validate', => @validate 'sourcelist'
      location.view = view
      @$('.sources-list').append view.el

    onLocationRemove: (location) ->
      @validate 'sourcelist'

    submitForm: (e) ->
      e.preventDefault()
      return if @validate()

      name = @$('#name').val()
      baseurl = @$('#baseurl').val()

      locations = @locations.map (l) ->
        json = l.toJSON()
        delete json.client
        json
      locations = _.filter locations, (l) -> l.path.length
      
      data = name: name, baseurl: baseurl, files: locations
      
      if @model
        @model.save data, wait: true, success: -> app.router.navigate '', trigger: true
      else
        app.Projects.create data, wait: true, success: (project) =>
          @client.save (project: project.id), success: (client) ->
            app.app.openConsole client.get 'session_id'

  module.exports = NewProjectView