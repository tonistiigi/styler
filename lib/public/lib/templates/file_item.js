define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('inner') + ' ' + (isHelper?'is-helper':'') }, {"class":true}));
buf.push('><div class="name">');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<span class="ext">');
var __val__ = extension
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span></div>');
if ( isActive)
{
buf.push('<div class="active-indicator">Active</div>');
}
if ( isOpen)
{
buf.push('<div class="open-indicator">Open</div>');
}
buf.push('</div>');
}
return buf.join("");
};
});