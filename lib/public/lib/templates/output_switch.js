define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="selected-item"><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (selectedClient.agenttype) }, {"class":true}));
buf.push('></div>');
 if (clients.length > 1) {
{
buf.push('<div class="more">' + escape((interp = clients.length-1) == null ? '' : interp) + ' more</div>');
}
 }
buf.push('<div class="useragent">');
var __val__ = selectedClient.useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div></div><div class="items">');
 clients.forEach( function (client) {
{
buf.push('<div');
buf.push(attrs({ 'data-client-id':(client.id), "class": ('item') + ' ' + ((selectedClient.id === client.id?"is-active":"")) }, {"class":true,"data-client-id":true}));
buf.push('><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (client.agenttype) }, {"class":true}));
buf.push('></div><div class="agentinfo"><div class="useragent">');
var __val__ = client.useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div class="url">');
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