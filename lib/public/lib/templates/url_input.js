define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="fields"><div class="input-row url"><div class="label">URL</div><div class="field"><div class="btn edit">Edit</div><div class="note-indicator"></div><input class="text url"/></div><div class="note"></div></div><div class="input-row path"><div class="label">Source directory</div><div class="field"><div class="btn browse browse-source">Browse</div><div class="note-indicator"></div><div class="input-container"><input class="text path"/><div class="completion-pfx"></div><div class="completion-sfx"></div></div></div><div class="note">No such directory was found on your hard drive.</div></div><div class="input-row type"><div class="label">Source file format</div><div class="field"><input');
buf.push(attrs({ 'type':("radio"), 'name':("type"), 'value':("css"), 'id':("type_css_" + id), "class": ('type') }, {"type":true,"name":true,"value":true,"id":true}));
buf.push('/><label');
buf.push(attrs({ 'for':("type_css_" + id) }, {"for":true}));
buf.push('>CSS</label><input');
buf.push(attrs({ 'type':("radio"), 'name':("type"), 'value':("stylus"), 'id':("type_stylus_" + id), "class": ('type') }, {"type":true,"name":true,"value":true,"id":true}));
buf.push('/><label');
buf.push(attrs({ 'for':("type_stylus_" + id) }, {"for":true}));
buf.push('>Stylus</label></div><div class="conversion-hint"></div></div><div class="input-row missing-files"><div class="label">When files are missing</div><div class="field"><input');
buf.push(attrs({ 'type':("radio"), 'name':("missing"), 'value':("ignore"), 'id':("missing_ignore_" + id), "class": ('missing-files') }, {"type":true,"name":true,"value":true,"id":true}));
buf.push('/><label');
buf.push(attrs({ 'for':("missing_ignore_" + id) }, {"for":true}));
buf.push('>Ignore</label><input');
buf.push(attrs({ 'type':("radio"), 'name':("missing"), 'value':("create"), 'id':("missing_create_" + id), "class": ('missing-files') }, {"type":true,"name":true,"value":true,"id":true}));
buf.push('/><label');
buf.push(attrs({ 'for':("missing_create_" + id) }, {"for":true}));
buf.push('>Create new files</label></div></div><div class="input-row stylus-out"><div class="label">Stylus output directory</div><div class="field"><div class="btn browse browse-stylus-out">Browse</div><div class="note-indicator"></div><div class="input-container"><input class="text stylus-out"/><div class="completion-pfx"></div><div class="completion-sfx"></div></div></div><div class="note">No such directory was found on your hard drive.</div></div><div class="stylus-switch-hint">Although Styler fully supports editing CSS stylesheets we encourage you to have a look at Stylus.\nStylus improves CSS format with many great features that help you become more productive.\nYou can learn more about Stylus from<a href="http://learnboost.github.com/stylus/" target="_blank">here</a>. You may also choose CSS for now and return later to this view to switch between formats.<div class="btn convert">Convert all files in this location to Stylus format</div><div class="clear"></div></div></div><div class="locations-info"><div class="head-note"><div class="msg no-url">Please select the URL for the CSS files location.</div><div class="msg no-files">No CSS files were found from your page that match this URL.</div><div class="msg has-files">This location contains following files:</div></div><div class="file-list"></div><div class="foot-note"><div class="msg no-matches">No matching source files were found from the source directory.</div><div class="msg some-matches"><span class="num-matches"></span>of<span class="num-files"></span>files were matched with the source files.</div><div class="msg all-matches">All files matched the source files.</div></div></div><div class="btn remove">Remove this location</div><div class="clear"></div>');
}
return buf.join("");
};
});