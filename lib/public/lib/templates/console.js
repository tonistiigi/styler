define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="main-toolbar"><div class="tools-group"><div class="tool tool-back"><label>Back to project list</label></div></div><div class="client-select client-select-toolbar"></div><div class="tools-group"><div class="tool tool-inspect"><label>Inspect on page</label></div><div class="tool tool-refresh"><label>Reload elements</label></div><div class="tool tool-identify"><label>Identify client</label></div><div class="tool tool-embed"><label>Single window mode</label></div><div class="tool tool-sidebyside"><label>Side by side single window</label></div></div><div class="tools-group"><div class="tool tool-edit"><label>Edit project</label></div><div class="tool tool-settings"><label>Settings</label></div></div><div class="sidebar-toggle"></div></div><div class="main-container"><div class="main"><div class="sidebar"><div class="client-select client-select-sidebar"></div><div class="block-heading"></div><div class="infobar infobar-outline overflow-row"></div><div class="styleinfo"></div><div class="resizer resizer-vertical"><div class="inner"><div class="thumb"></div></div></div><div class="elements-outline"></div><div class="no-clients-fallback"><div class="connect-helper">To see real time updates and live debugging data open another browser window at<span class="url"></span>and connect it to Styler using either injected code, bookmarklet or an extension.</div><div class="hide-hint">If you don\'t need the client area you can click the collapse icon to hide it.</div></div></div><div class="resizer resizer-horizontal"><div class="inner"><div class="thumb"></div></div></div><div class="main-content"><div class="editor-container"></div></div></div><div class="cli-container"></div></div>');
}
return buf.join("");
};
});