define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="selection"> </div><div class="options"><div class="option mode-live">Live</div><div class="option mode-save">On Save</div></div>');
}
return buf.join("");
};
});