define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="warning-img"></div><div class="warning-message">The Console part of this application is currently only tested in Webkit based browsers (Chorme & Safari) and Firefox 10+. Please use these browsers for best results. You can use any modern browser (Chrome, Firefox, Safari, IE9+, Mobile Safari) in the client side of the app.</div><div onclick="window.sessionStorage.setItem(\'_ignore_agent\', 1); window.location.reload()" class="ignore button">Ignore this warning</div>');
}
return buf.join("");
};
});