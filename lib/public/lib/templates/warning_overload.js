define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="warning-img"></div><div class="warning-message">Application was opened in another window for the same project.<br/>Refresh to force this window.</div><div onclick="window.location.reload()" class="button reload">Reload window</div><div class="hint">If you don\'t need this window any more you can safely close it.</div>');
}
return buf.join("");
};
});