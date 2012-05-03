define(function(require, exports, module){
  require("vendor/jade"); 
  module.exports = function anonymous(locals, attrs, escape, rethrow) {
var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div');
buf.push(attrs({ "class": ('selection') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('options') }));
buf.push('><div');
buf.push(attrs({ "class": ('label') }));
buf.push('>Tab Size</div><div');
buf.push(attrs({ 'data-tabsize':(2), "class": ('option') + ' ' + ('option-size') + ' ' + ('option-size-2') }));
buf.push('>2</div><div');
buf.push(attrs({ 'data-tabsize':(3), "class": ('option') + ' ' + ('option-size') + ' ' + ('option-size-3') }));
buf.push('>3</div><div');
buf.push(attrs({ 'data-tabsize':(4), "class": ('option') + ' ' + ('option-size') + ' ' + ('option-size-4') }));
buf.push('>4</div><div');
buf.push(attrs({ 'data-tabsize':(8), "class": ('option') + ' ' + ('option-size') + ' ' + ('option-size-8') }));
buf.push('>8</div><div');
buf.push(attrs({ "class": ('separator') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('option') + ' ' + ('option-format') }));
buf.push('>Reformat file</div><div');
buf.push(attrs({ "class": ('separator') }));
buf.push('></div><div');
buf.push(attrs({ "class": ('option') + ' ' + ('option-type') }));
buf.push('>Soft tabs(spaces)</div></div>');
}
return buf.join("");
};
});