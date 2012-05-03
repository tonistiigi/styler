define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('client-item') + ' ' + (connected ? "active" : "disabled") }));
buf.push('><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (agenttype) }));
buf.push('></div><div');
buf.push(attrs({ "class": ('name') }));
buf.push('>');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div');
buf.push(attrs({ "class": ('useragent') }));
buf.push('>');
var __val__ = useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><a');
buf.push(attrs({ "class": ('btn') + ' ' + ('launch') }));
buf.push('>Start</a></div>');
}
return buf.join("");
};
});