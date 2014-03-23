define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="selector overflow-flex"></div><div class="element-tools overflow-fixed"><div data-class="hover" class="pseudo-indicator hover"></div><div data-class="focus" class="pseudo-indicator focus"></div><div data-class="active" class="pseudo-indicator active"></div><div data-class="visited" class="pseudo-indicator visited"></div><div class="pseudo-selector-cont"><div tabIndex="10" class="pseudo-selector selectable"><div class="options"><div data-class="hover" class="option hover">Hover</div><div data-class="focus" class="option focus">Focus</div><div data-class="active" class="option active">Active</div><div data-class="visited" class="option visited">Visited</div></div></div></div><div class="parent-selector-cont"><div tabIndex="11" class="parent-selector selectable"><div class="options"></div></div></div><div class="media-selector-cont"><div tabIndex="12" class="media-selector selectable"><div class="options"><div data-class="screen" class="option screen">Screen</div><div data-class="print" class="option print">Print</div><div data-class="tv" class="option tv">TV</div></div></div></div><div class="element-rules"><div class="inner"></div></div></div>');
}
return buf.join("");
};
});