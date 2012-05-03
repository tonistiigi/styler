var $ = function (id) { return document.getElementById(id) };
var $$ = function (el, selector) { return el.querySelector(selector) };

function startEditMode() {
  $$(document,".info.view").style.display = "none";
  $$(document,".info.edit").style.display = "block";
  $("url").value = conf.url;
  $("url").focus();
};
function dismissEditMode() {
  $$(document,".info.view").style.display = "block";
  $$(document,".info.edit").style.display = "none";
  $$(document,".info.view .url").innerHTML = conf.url;
};
function saveInfo() {
  self.port.emit("seturl", $("url").value);
  dismissEditMode();
  close();
};
function reconnect() {
  self.port.emit("reconnect");
  close();
};
function launchHome() {
  self.port.emit("openurl", conf.url);
  close();
};
function clear() {
  document.body.style.display = "none";
};

function init(conf){
  window.conf = conf;
  if (conf.connected) {
    $("is_connected").style.display = "block";
    $("not_connected").style.display = "none";
    $("items").style.display = "block";
    
    if (conf.active) {
      $$(document,".item.launch").style.display = "block";
      $$(document,".item.start").style.display = "none";
    }
    else {
      $$(document,".item.start").style.display = "block";
      $$(document,".item.launch").style.display = "none";
    }
    $$(document,".item.home").style.display = "block";
  }
  else {
    $("not_connected").style.display = "block";
    $("is_connected").style.display = "none";
    $("items").style.display = "none";
  }
  
  dismissEditMode();
  document.body.style.display = "block";  
}

self.port.on("init", init);
self.port.on("clear", clear);

$$(document,".btn.edit").addEventListener("click", startEditMode);
$$(document,".btn.save").addEventListener("click", saveInfo);
$$(document,".btn.cancel").addEventListener("click", dismissEditMode);

$$(document,".item.start").addEventListener("click", launchConsole);
$$(document,".item.launch").addEventListener("click", launchConsole);
$$(document,".item.home").addEventListener("click", launchHome);
$$(document,"a.reconnect").addEventListener("click", reconnect);

function launchConsole() {
  self.port.emit("launchConsole");  
}