define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('selection') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('options') }));
buf.push('><div');
buf.push(attrs({ "class": ('option') + ' ' + ('mode-live') }));
buf.push('>Live</div><div');
buf.push(attrs({ "class": ('option') + ' ' + ('mode-save') }));
buf.push('>On Save</div></div>');
}
return buf.join("");
};
});