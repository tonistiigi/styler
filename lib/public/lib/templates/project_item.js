define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('project-item') + ' ' + ((isActive ? "expanded" : "") + " " + (clientCount ? "has-clients" : "")) }));
buf.push('><div');
buf.push(attrs({ "class": ('project-line') }));
buf.push('><div');
buf.push(attrs({ "class": ('expand') }));
buf.push('><div');
buf.push(attrs({ "class": ('inner') }));
buf.push('></div></div><div');
buf.push(attrs({ "class": ('project-name') }));
buf.push('><div');
buf.push(attrs({ "class": ('name') }));
buf.push('>');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div></div>');
if ( clientCount > 0)
{
buf.push('<div');
buf.push(attrs({ "class": ('num-clients') }));
buf.push('>');
var __val__ = clientCount + (clientCount > 1 ? " connections":" connection")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div>');
}
else
{
buf.push('<div');
buf.push(attrs({ "class": ('no-clients') }));
buf.push('>No connections</div>');
}
buf.push('<div');
buf.push(attrs({ "class": ('buttons') }));
buf.push('><a');
buf.push(attrs({ "class": ('btn') + ' ' + ('delete') }));
buf.push('></a><a');
buf.push(attrs({ "class": ('btn') + ' ' + ('edit') }));
buf.push('></a><a');
buf.push(attrs({ "class": ('btn') + ' ' + ('launch') + ' ' + ('projectlaunch') }));
buf.push('>Start</a><a');
buf.push(attrs({ 'href':(baseurl), 'target':("_blank"), "class": ('btn') + ' ' + ('open') }));
buf.push('>Open page</a></div></div>');
if ( isActive)
{
buf.push('<div');
buf.push(attrs({ "class": ('clients') }));
buf.push('></div>');
}
buf.push('</div>');
}
return buf.join("");
};
});