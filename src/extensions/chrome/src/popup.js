var bgview = null;

var $ = function (id) { return document.getElementById(id) };
var $$ = function (el, selector) { return el.querySelector(selector) };

function startEditMode(){
  $$(document,".info.view").style.display = "none";
  $$(document,".info.edit").style.display = "block";
  $("url").value = bgview.url;
  $("url").focus();
  $("url").addEventListener('keyup', onKeyUp);
};

function onKeyUp(e){
  if (e.keyCode == 13) { //Return
    saveInfo();
  }
  else if (e.keyCode == 27) {
    dismissEditMode();
  }
}

function dismissEditMode(){
  $$(document,".info.view").style.display = "block";
  $$(document,".info.edit").style.display = "none";
  $$(document,".info.view .url").innerHTML = bgview.url;
};
function saveInfo(){
  bgview.saveURL($("url").value);
  dismissEditMode();
  close();
};
function reconnect(){
  bgview.location.reload();
  close();
};
function launchHome(){
  chrome.tabs.create({url: bgview.url});
  close();
};
function launchConsole(){
  bgview.launchConsole();
};

document.addEventListener("DOMContentLoaded", function(){
  var views = chrome.extension.getViews();
  for(var i = 0 ; i < views.length ; i++){
    if(views[i].id == "styler_background")
      bgview = views[i];
  }

  if(bgview.connected){
    $("is_connected").style.display = "block";
    $("not_connected").style.display = "none";
    $("items").style.display = "block";
    
    chrome.windows.getCurrent(function (win) {
      chrome.tabs.query({active: true, windowId: win.id}, function (tabs) {
        var tab = tabs[0];
        bgview.checkProjectPath(tab.url, function (hasProject) {
          if (hasProject) {
            $$(document, ".item.launch").style.display = "block";
          }
          else {
            $$(document, ".item.start").style.display = "block";  
          }
        });
      });
    });
    $$(document, ".item.home").style.display = "block";
  }
  else {
    $("not_connected").style.display = "block";
    $("is_connected").style.display = "none";
    $("items").style.display = "none";
  }

  dismissEditMode();
  $$(document, ".item.start").addEventListener('click', launchConsole);
  $$(document, ".item.launch").addEventListener('click', launchConsole);
  $$(document, ".item.home").addEventListener('click', launchHome);
  $$(document, ".btn.save").addEventListener('click', saveInfo);
  $$(document, ".btn.edit").addEventListener('click', startEditMode);
  $$(document, ".btn.cancel").addEventListener('click', dismissEditMode);
  $$(document, ".head#not_connected > .hint > a").addEventListener('click', reconnect);
});