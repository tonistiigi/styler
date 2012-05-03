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
buf.push('>The Console part of this application is currently only tested in Webkit based browsers (Chorme & Safari) and Firefox 10+. Please use these browsers for best results. You can use any modern browser (Chrome, Firefox, Safari, IE9+, Mobile Safari) in the client side of the app.\n</div><div');
buf.push(attrs({ 'onclick':("window.sessionStorage.setItem('_ignore_agent', 1); window.location.reload()"), "class": ('ignore') + ' ' + ('button') }));
buf.push('>Ignore this warning\n</div>');
}
return buf.join("");
};
});