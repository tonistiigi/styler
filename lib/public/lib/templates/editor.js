define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="toolbar"><div class="tools-group"><div class="tool tool-file-list"></div><div class="tool tool-save is-disabled"></div></div><div class="tabs"></div><div class="search"></div></div><div class="block-heading"></div><div class="infobar infobar-editor"><div class="infobar-toggle"></div><div class="editor-info"><div class="locking-toggle"></div><div class="file-filter"><input type="checkbox"/>Only active files</div><div class="selected-rule"><div class="selector"></div><div class="selector-elements"></div><div class="selection-hint"><div class="inner"></div></div></div></div></div><div class="filebrowser"></div><div class="editor"></div><div class="statusbar"></div>');
}
return buf.join("");
};
});