define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('selected-item') }));
buf.push('><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (selectedClient.agenttype) }));
buf.push('></div>');
 if (clients.length > 1) {
{
buf.push('<div');
buf.push(attrs({ "class": ('more') }));
buf.push('>' + escape((interp = clients.length-1) == null ? '' : interp) + ' more</div>');
}
 }
buf.push('<div');
buf.push(attrs({ "class": ('useragent') }));
buf.push('>');
var __val__ = selectedClient.useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div></div><div');
buf.push(attrs({ "class": ('items') }));
buf.push('>');
 clients.forEach( function (client) {
{
buf.push('<div');
buf.push(attrs({ 'data-client-id':(client.id), "class": ('item') + ' ' + ((selectedClient.id === client.id?"is-active":"")) }));
buf.push('><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (client.agenttype) }));
buf.push('></div><div');
buf.push(attrs({ "class": ('agentinfo') }));
buf.push('><div');
buf.push(attrs({ "class": ('useragent') }));
buf.push('>');
var __val__ = client.useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div');
buf.push(attrs({ "class": ('url') }));
buf.push('>');
var __val__ = client.url
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div></div></div>');
}
 } )
buf.push('</div>');
}
return buf.join("");
};
});