var browserWindows = require("windows").browserWindows,
    contextMenu = require("context-menu"),
    data = require("self").data,
    Page = require("page-worker").Page,
    Panel = require("panel").Panel,
    storage = require("simple-storage").storage,
    tabs = require("tabs"),
    Widget = require("widget").Widget;

var ICONS = {
  DEFAULT: data.url("icons/icon128.png"),
  DISCONNECTED: data.url("icons/icon_no_connection.png"),
  CONNECTED: data.url("icons/icon_has_connection.png"),
  ACTIVE: data.url("icons/icon_active.png")
};

if (!storage.url) {
  storage.url = "http://localhost:5100/";
}
var url = storage.url,
    connected = false,
    bgPage = null;

exports.main = function(options, callbacks) {
  var panel = Panel({
    width: 210,
    height: 170,
    contentURL: data.url("popup/popup.html"),
    contentScriptFile: [
      data.url("popup/popup.js")
    ],
    onShow: function() {
      panel.port.emit("clear");
      var conf = {
        url: url,
        connected: connected,
        active: false
      };
      if (connected) {
        var tab = tabs.activeTab;
        postCallback({type: "checkproject", url: tab.url}, function (info) {
          conf.active = info.hasproject;
          panel.port.emit("init", conf);
        });
      }
      else {
        panel.port.emit("init", conf);
      }
    }
  });

  panel.port.on("openurl", function (url) {
    tabs.open(url);
    panel.hide();
  });

  panel.port.on("seturl", function(value){
    if (!value.length) return;
    if (value[value.length-1] != '/') value += '/';
    url = storage.url = value;
    doConnect();
    panel.hide();
  });

  panel.port.on("reconnect", doConnect);
  panel.port.on("launchConsole", launchConsole);

  function launchConsole() {
    var worker = tabs.activeTab.attach({contentScript: inlineFunction(CONTENT_SCRIPTS.LAUNCH, getInjectCode())});
    worker.port.on("activate", function(sessionId){
      browserWindows.open({
        type: "popup",
        width: 800,
        height: 600,
        url: url + sessionId
      });
      panel.hide();
    });
  }

  var icon = Widget({
    id: 'styler_icon',
    label: 'Styler',
    panel: panel,
    contentURL: ICONS.DEFAULT
  });


  function doConnect() {
    if (bgPage) {
      bgPage.destroy();
    }
    bgPage = Page({
      contentURL: data.url("pages/bg.html"),
      contentScriptFile: data.url("lib/message_proxy.js"),
      contentScriptWhen: "ready",
      onMessage: function (message) {
        switch (message.type) {

          case 'show_connected':
            showConnectedIcon();
          break;

          case 'show_disconnected':
            showDisconnectedIcon();
          break;

          case 'ready':
            bgPage.postMessage({type: "loadSocketIO", url: url});
          break;

          case 'log':
            console.log("log >", message.data);
          break;

          case 'setFocus':
            setFocus(message.data);
          break;

          case 'response':
            var func = _callbacks[message.data.callback];
            if (func)
              func(message.data);
          break;
        }
      }
    });
    createMenu();
  };


  function showDisconnectedIcon() {
    connected = false;
    for each (var window in browserWindows){
      var view = icon.getView(window);
      view.contentURL = ICONS.DISCONNECTED;
    }
  }

  var _callbacks = {};
  function postCallback(data, callback) {
    var id = ~~(Math.random() * 10e6);
    _callbacks[id] = callback;
    data['callback'] = id;
    bgPage.postMessage(data);
  }

  function updateTabIcon(tab, window) {
    postCallback({type: "checkproject", url: tab.url}, function (info) {
      var view = icon.getView(window);
      if(info.hasproject){
        view.contentURL = ICONS.ACTIVE;
        tab.attach({contentScript: getInjectCode()});
      }
      else {
        view.contentURL = ICONS.CONNECTED;
      }
    });
  }

  function showConnectedIcon() {
    connected = true;
    for each (var window in browserWindows){
      var tabs = window.tabs;
      var activeTab = tabs.activeTab;
      updateTabIcon(activeTab, window);
    }
  }

  function windowForTab(tab) {
    for each (var window in browserWindows){
      for each (var t in window.tabs)
        if (t == tab){
          return window;
        }
    }
    return null;
  }

  function setFocus(titleId) {
    for each (var tab in tabs){
      var title = tab.title;
      if (title.match(new RegExp("\\("+titleId+"\\)$"))) {
        tab.activate();
        var win = windowForTab(tab);
        if (win)
          win.activate();
        break;
      }
    }
  }

  tabs.on("ready", function(tab){
    var win = windowForTab(tab);
    if(!win || win.tabs.activeTab!=tab){;
     return false;
    }
    updateTabIcon(tab, win);
  });

  tabs.on("activate", function(tab){
    updateTabIcon(tab, windowForTab(tab));
  });

  var cmItemInstall, cmItemInspect;
  function createMenu(){
    if(cmItemInstall) cmItemInstall.destroy();
    if(cmItemInspect) cmItemInspect.destroy();
    cmItemInstall = contextMenu.Item({
      label: "Start using Styler on this page",
      context: contextMenu.PageContext(),
      contentScript: inlineFunction(CONTENT_SCRIPTS.ACTIVATE, '"' + url + 'styler.js"'),
      onMessage: function(msg){
        if(msg == 'activate') launchConsole();
      }
    });
    cmItemInstall = contextMenu.Item({
      label: "Inspect in Styler",
      context: contextMenu.SelectorContext("*"),
      contentScript: inlineFunction(CONTENT_SCRIPTS.INSPECT, '"' + url + 'styler.js"'),
      onMessage: function(msg){
        if(msg.message == 'activate') return launchConsole();
        if(msg.message == 'focuschange') {
          for each (var window in browserWindows){
            for each (var tab in window.tabs){
              if(tab.url == url + msg.session){
                tab.activate();
                window.activate();
                return;
              }
            }
          }
        }
      }
    });
  }

  function inlineFunction(func) {
    var args = Array.prototype.slice.call(arguments, 1);
    return '(' + func.toString()  + ')(' + args.join(', ') + ')';
  }

  // Next functions can't be called(or reference closure vars).
  // They are turned into strings and injected to the page.
  var CONTENT_SCRIPTS = {

    INJECT: function (url) {
      var script = false;
      var scripts = document.getElementsByTagName('script');
      for(var i=0 ; i < scripts.length ; i++) {
        if (scripts[i].getAttribute('src') == url) {
          script = scripts[i];
          break;
        }
      }
      if (!script) {
        script = document.createElement('script');
        var parent =  document.getElementsByTagName('head')[0] || document.body;
        script.setAttribute('src', url);
        parent.appendChild(script);
      }
      /*
      document.addEventListener('requestfocuschange', function(e){
        port.postMessage({message: 'requestfocuschange', session: e.detail});
      });
      document.addEventListener('activatefrominspector', function(e){
        port.postMessage({message: 'activate', session: e.detail});
      });
      */
      return script;

    },

    LAUNCH: function (script) {
      var port = self.port;
      var sessionId = script.getAttribute('data-session-id');

      if (sessionId && sessionId.length) {
        port.emit('activate', sessionId);
      }
      else {
        document.addEventListener('stylerload', function(e) {
          port.emit('activate', e.detail);
        });
      }
    },

    ACTIVATE: function(url) {
      self.on('context', function () {
        var scripts = document.getElementsByTagName('script');
        var script = false;
        for (var i = 0 ; i < scripts.length ; i++) {
          if (scripts[i].getAttribute('src') == url)
            return false
        }
        return true;
      });
      self.on('click', function () {
        self.postMessage('activate');
      });
    },

    INSPECT: function(url) {
      self.on('context', function () {
        var scripts = document.getElementsByTagName('script');
        var script = false;
        for (var i = 0 ; i < scripts.length ; i++) {
          if (scripts[i].getAttribute('src') == url)
            return true
        }
        return false;
      });
      self.on('click', function () {
        document.addEventListener('requestfocuschange', function (e) {
          self.postMessage({message: 'focuschange', session: e.detail});
        });
        document.addEventListener('activatefrominspector', function (e) {
          self.postMessage({message: 'activate', session: e.detail});
        });
        var customEvent = document.createEvent('CustomEvent');
        customEvent.initCustomEvent('stylerinspect', true, true, null);
        document.dispatchEvent(customEvent);
      });
    }

  };

  function getInjectCode(){
    return inlineFunction(CONTENT_SCRIPTS.INJECT, '"' + url + 'styler.js"');
  };


  doConnect();
};
