requirejs = require "requirejs"
Backbone = require './backbone-socketio-backend'
{ProjectList, ClientList, SettingsList} = requirejs "./../public/lib/models"

# Creates static instances of Backbone collections to be used on server side.
exports.Clients = new ClientList null, backend: "clients"
exports.Projects = new ProjectList null, backend: "projects", clients: exports.Clients
exports.Settings = new SettingsList null, backend: "settings"

Backbone.connector.connect exports.Projects, true
Backbone.connector.connect exports.Clients
Backbone.connector.connect exports.Settings, true

exports.Projects.fetch()

# Create empty Settings instance if not found.
exports.Settings.fetch success: ->
  exports.Settings.create {}, wait: true if exports.Settings.size() == 0
