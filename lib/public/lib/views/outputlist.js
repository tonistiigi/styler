(function() {
  define(function(require, exports, module) {
    var Backbone, OutputListView, OutputView;
    Backbone = require("backbone");
    OutputView = require("lib/views/output");
    OutputListView = Backbone.View.extend({
      initialize: function(list) {
        this.list = list;
        this.list.bind("add", this.addOne, this);
        this.list.bind("reset", this.addAll, this);
        this.list.bind("all", this.render, this);
        return this.addAll();
      },
      addOne: function(p) {
        var view;
        view = new OutputView({
          model: p
        });
        return $(this.el).append(view.render().el);
      },
      addAll: function() {
        return this.list.each(this.addOne, this);
      }
    });
    return module.exports = OutputListView;
  });
}).call(this);
