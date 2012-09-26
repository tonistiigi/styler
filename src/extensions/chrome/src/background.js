var ioLoaded = false,
    tabStates = {},
    lastInspectTime = 0;

var STATES = {DISCONNECTED: 1, CONNECTED: 2, ACTIVE: 3};

this.id = "styler_background"; // Remember so popup finds it.
this.url = localStorage.getItem("url") || "http://localhost:5100/";
this.connected = false;
this.socket = null;

function loadSocketIO() {
  var script = document.createElement("script");
  script.onload = function(){
    tryConnect();
  }
  script.onerror = function(){
    setTimeout(loadSocketIO, 30000);
    document.body.removeChild(script);
    showDisconnectedIcon();
  }
  script.src = "socket.io.js";
  document.body.appendChild(script);
}
showDisconnectedIcon();

function tryConnect() {
  socket = io.connect(url + "info");
  socket.on("connect", function(){
    showConnectedIcon();
  });
  socket.on('focus', function(id){
    chrome.tabs.query({title: "*("+id+")"}, function (tabs) {
      if (tabs.length) {
        chrome.tabs.update(tabs[0].id, {active: true});
        chrome.windows.update(tabs[0].windowId, {focused: true});
      }
    });
  });
  socket.on("disconnect", function(){
    showDisconnectedIcon();
  });
}

function saveURL(url) {
  if (!url.length)
    return;
  if (url[url.length - 1] != "/")
    url += "/";

  localStorage.setItem("url", url);
  location.reload();
}

function checkProjectPath(path, cb) {
  socket.emit("checkproject", path, cb);
}

function showDisconnectedIcon() {
  connected = false;
  chrome.tabs.query({}, function (tabs) {
    for (var i = 0 ; i < tabs.length ; i++) {
      chrome.browserAction.setIcon({path: "../icons/icon_no_connection.png", tabId: tabs[i].id});
    }
  });
}

function showConnectedIcon() {
  connected = true;
  chrome.tabs.query({}, function (tabs) {
    for (var i = 0 ; i < tabs.length ; i++) {
      updateTabIcon(tabs[i]);
    }
  });
}

function updateTabIcon(tab) {
  checkProjectPath(tab.url, function (hasProject) {
    if (hasProject) {
      chrome.browserAction.setIcon({path: "../icons/icon_active.png", tabId: tab.id});
      chrome.tabs.executeScript(tab.id,{code: getInjectCode()});
      tabStates[tab.id] = STATES.ACTIVE;
    }
    else {
      chrome.browserAction.setIcon({path: "../icons/icon_has_connection.png", tabId: tab.id});
      tabStates[tab.id] = STATES.CONNECTED;
    }
  });
}

function onUpdated(tabId) {
  if (connected) {
    chrome.tabs.get(tabId, function (tab) {
      updateTabIcon(tab, true);
      if (tab.active) {
        makeContextMenu(tabId);
      }
    });
  }
  else {
    chrome.tabs.get(tabId, function (tab) {
      chrome.browserAction.setIcon({path: "../icons/icon_no_connection.png", tabId: tab.id});
      tabStates[tabId] = STATES.DISCONNECTED;
      if (tab.active) {
        makeContextMenu(tabId);
      }
    });
  }
}

chrome.tabs.onUpdated.addListener(onUpdated);

chrome.tabs.onActiveChanged.addListener(function (tabId, selectInfo) {
  makeContextMenu(tabId);
  onUpdated(tabId);
});

chrome.windows.onFocusChanged.addListener(function (windowId) {
  if (windowId > 0) {
    chrome.tabs.query({active: true, windowId: windowId}, function (tabs) {
      if (tabs[0]) {
        makeContextMenu(tabs[0].id);
      }
    });
  }
});

var inProgress = false;
function makeContextMenu(tabId){
  if (inProgress) {
    return;
  }
  inProgress = true;
  chrome.contextMenus.removeAll( function () {
    var state = tabStates[tabId];
    if (state == STATES.CONNECTED) {
      chrome.contextMenus.create({
        title: 'Start using Styler in this page',
        onclick: function (info, tab) {
          launchConsole();
        }
      });
    }
    else if (state == STATES.ACTIVE) {
      chrome.contextMenus.create({
        title: 'Inspect in Styler',
        contexts: ['all'],
        onclick: function(info, tab){
          inspectConsole();
        }
      });
    }
    inProgress = false;
  });
}

chrome.extension.onConnect.addListener(function (port) {
  port.onMessage.addListener(function (msg) {
    switch (msg.message){
      case 'activate':
        var currentTime = new Date();
        if (currentTime - lastInspectTime < 500) {
          return;
        }
        lastInspectTime = currentTime;
        chrome.windows.create({
          type: "popup",
          width: 900,
          height: 700,
          url: this.url + msg.session
        });
      break;

      case 'requestfocuschange':
        var popupurl = url + msg.session;
        popupurl = popupurl.replace(/:\d+/, "");
        chrome.tabs.query({url: popupurl}, function (tabs) {
          if (tabs[0]) {
            chrome.tabs.update(tabs[0].id, {active: true});
          }
        });
      break;
    }
  });
});



function inlineFunction(func) {
  var args = Array.prototype.slice.call(arguments, 1);
  return '(' + func.toString()  + ')(' + args.join(', ') + ')';
}

// Next functions can't be called(or reference closure vars).
// They are turned into strings and injected to the page.
var CONTENT_SCRIPTS = {

  INJECT: function (url) {
    var port = chrome.extension.connect();
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
    document.addEventListener('requestfocuschange', function(e){
      port.postMessage({message: 'requestfocuschange', session: e.detail});
    });
    document.addEventListener('activatefrominspector', function(e){
      port.postMessage({message: 'activate', session: e.detail});
    });

    return script;
  },

  LAUNCH: function (script) {
    var port = chrome.extension.connect();
    var sessionId = script.getAttribute('data-session-id');

    if (sessionId && sessionId.length) {
      port.postMessage({message: 'activate', session: sessionId});
    }
    else {
      document.addEventListener('stylerload', function(e) {
        port.postMessage({message: 'activate', session: e.detail});
      });
    }
  },

  INSPECT: function() {
    var inspect = document.createEvent('CustomEvent');
    inspect.initCustomEvent('stylerinspect', true, true, null);
    document.dispatchEvent(inspect);
  }

};

function getInjectCode(){
  return inlineFunction(CONTENT_SCRIPTS.INJECT, '"' + url + 'styler.js"');
};

function launchConsole(){
  var code = inlineFunction(CONTENT_SCRIPTS.LAUNCH, getInjectCode());
  chrome.tabs.executeScript(null, {code: code});
};

function inspectConsole(){
  var code = inlineFunction(CONTENT_SCRIPTS.INSPECT);
  chrome.tabs.executeScript(null, {code: code});
};

document.addEventListener('DOMContentLoaded', function(){
  loadSocketIO();
});
