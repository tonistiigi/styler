define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('warning-img') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('warning-message') }));
buf.push('>Connection to the server was lost.\n<br');
buf.push(attrs({  }));
buf.push('/>Please start Styler daemon.\n</div>');
}
return buf.join("");
};
});