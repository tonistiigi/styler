define(function(require, exports, module){
  require("vendor/jade");
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
if ( mode == 'edit')
{
buf.push('<h2 class="title">Edit project</h2>');
}
else
{
buf.push('<h2 class="title">Create new project</h2><div class="descr">Fill in the details below to start using Styler in your page.</div>');
}
buf.push('<form class="new-project"><div class="errors-summary"><div class="heading">Please review the following issues before submitting:</div><div class="errors"></div></div><div class="input-row name"><div class="label"><label>Project name</label></div><div class="field"><div class="note-indicator"></div><input id="name" class="text"/></div><div class="note"></div></div><div class="input-row baseurl"><div class="label"> <label>Base URL</label></div><div class="field"> <div class="note-indicator"></div><input id="baseurl" class="text"/></div><div class="note"></div><div class="hint">Base URL defines the enrtypoint for your projects pages. All pages that start with this URL are counted as being part of the project.</div></div><div class="sources"><div class="heading">Source locations</div><div class="hint"></div><div class="sources-list"></div><div class="btn add-source">Add new location</div></div><div><input type="submit" value="Save project"/></div></form>');
}
return buf.join("");
};
});