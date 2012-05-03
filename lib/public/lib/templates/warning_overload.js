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
buf.push('>Application was opened in another window for the same project.\n<br');
buf.push(attrs({  }));
buf.push('/>Refresh to force this window.\n</div><div');
buf.push(attrs({ 'onclick':("window.location.reload()"), "class": ('button') + ' ' + ('reload') }));
buf.push('>Reload window</div><div');
buf.push(attrs({ "class": ('hint') }));
buf.push('>If you don\'t need this window any more you can safely close it.</div>');
}
return buf.join("");
};
});