self.on('message', function (msg) {
  var customEvent = document.createEvent('CustomEvent');
  customEvent.initCustomEvent('message', true, true, msg);
  document.dispatchEvent(customEvent);
});

document.addEventListener('emit', function(e){
  self.postMessage(e.detail);
});
