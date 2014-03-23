define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('project-item') + ' ' + ((isActive ? "expanded" : "") + " " + (clientCount ? "has-clients" : "")) }, {"class":true}));
buf.push('><div class="project-line"><div class="expand"><div class="inner"></div></div><div class="project-name"><div class="name">');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div></div>');
if ( clientCount > 0)
{
buf.push('<div class="num-clients">');
var __val__ = clientCount + (clientCount > 1 ? " connections":" connection")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div>');
}
else
{
buf.push('<div class="no-clients">No connections</div>');
}
buf.push('<div class="buttons"><a class="btn delete"></a><a class="btn edit"></a><a class="btn launch projectlaunch">Start</a><a');
buf.push(attrs({ 'href':(baseurl), 'target':("_blank"), "class": ('btn') + ' ' + ('open') }, {"href":true,"target":true}));
buf.push('>Open page</a></div></div>');
if ( isActive)
{
buf.push('<div class="clients"></div>');
}
buf.push('</div>');
}
return buf.join("");
};
});