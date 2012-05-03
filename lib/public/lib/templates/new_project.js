define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
if ( mode == 'edit')
{
buf.push('<h2');
buf.push(attrs({ "class": ('title') }));
buf.push('>Edit project</h2>');
}
else
{
buf.push('<h2');
buf.push(attrs({ "class": ('title') }));
buf.push('>Create new project</h2><div');
buf.push(attrs({ "class": ('descr') }));
buf.push('>Fill in the details below to start using Styler in your page.</div>');
}
buf.push('<form');
buf.push(attrs({ "class": ('new-project') }));
buf.push('><div');
buf.push(attrs({ "class": ('errors-summary') }));
buf.push('><div');
buf.push(attrs({ "class": ('heading') }));
buf.push('>Please review the following issues before submitting:</div><div');
buf.push(attrs({ "class": ('errors') }));
buf.push('></div></div><div');
buf.push(attrs({ "class": ('input-row') + ' ' + ('name') }));
buf.push('><div');
buf.push(attrs({ "class": ('label') }));
buf.push('><label>Project name</label></div><div');
buf.push(attrs({ "class": ('field') }));
buf.push('><div');
buf.push(attrs({ "class": ('note-indicator') }));
buf.push('></div><input');
buf.push(attrs({ 'id':('name'), "class": ('text') }));
buf.push('/></div><div');
buf.push(attrs({ "class": ('note') }));
buf.push('></div></div><div');
buf.push(attrs({ "class": ('input-row') + ' ' + ('baseurl') }));
buf.push('><div');
buf.push(attrs({ "class": ('label') }));
buf.push('><label>Base URL</label></div><div');
buf.push(attrs({ "class": ('field') }));
buf.push('><div');
buf.push(attrs({ "class": ('note-indicator') }));
buf.push('></div><input');
buf.push(attrs({ 'id':('baseurl'), "class": ('text') }));
buf.push('/></div><div');
buf.push(attrs({ "class": ('note') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('hint') }));
buf.push('>Base URL defines the enrtypoint for your projects pages. All pages that start with this URL are counted as being part of the project.</div></div><div');
buf.push(attrs({ "class": ('sources') }));
buf.push('><div');
buf.push(attrs({ "class": ('heading') }));
buf.push('>Source locations</div><div');
buf.push(attrs({ "class": ('hint') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('sources-list') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('btn') + ' ' + ('add-source') }));
buf.push('>Add new location</div></div><div><input');
buf.push(attrs({ 'type':("submit"), 'value':("Save project") }));
buf.push('/></div></form>');
}
return buf.join("");
};
});