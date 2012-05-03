define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('inner') + ' ' + (isHelper?'is-helper':'') }));
buf.push('><div');
buf.push(attrs({ "class": ('name') }));
buf.push('>');
var __val__ = name
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<span');
buf.push(attrs({ "class": ('ext') }));
buf.push('>');
var __val__ = extension
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span></div>');
if ( isActive)
{
buf.push('<div');
buf.push(attrs({ "class": ('active-indicator') }));
buf.push('>Active</div>');
}
if ( isOpen)
{
buf.push('<div');
buf.push(attrs({ "class": ('open-indicator') }));
buf.push('>Open</div>');
}
buf.push('</div>');
}
return buf.join("");
};
});