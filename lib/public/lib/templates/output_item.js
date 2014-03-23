define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('client-item') + ' ' + (connected ? "active" : "disabled") }, {"class":true}));
buf.push('><div');
buf.push(attrs({ "class": ('agenttype') + ' ' + (agenttype) }, {"class":true}));
buf.push('></div><div class="name">');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div class="useragent">');
var __val__ = useragent
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><a class="btn launch">Start</a></div>');
}
return buf.join("");
};
});