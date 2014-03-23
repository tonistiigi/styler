define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="selection"> </div><div class="options"><div class="label">Tab Size</div><div data-tabsize=\'2\' class="option option-size option-size-2">2</div><div data-tabsize=\'3\' class="option option-size option-size-3">3</div><div data-tabsize=\'4\' class="option option-size option-size-4">4</div><div data-tabsize=\'8\' class="option option-size option-size-8">8</div><div class="separator"></div><div class="option option-format">Reformat file</div><div class="separator"></div><div class="option option-type">Soft tabs(spaces)</div></div>');
}
return buf.join("");
};
});