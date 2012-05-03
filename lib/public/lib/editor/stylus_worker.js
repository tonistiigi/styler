define(function(require, exports, module) {
    
var oop = require("ace/lib/oop");
var Mirror = require("ace/worker/mirror").Mirror;
var getStats = require("../../lib/editor/cssstats");

var Worker = exports.Worker = function(sender) {
    Mirror.call(this, sender);
    this.setTimeout(200);
    
    this.statsTimeout = 0;
    this.updateStats = Worker.prototype.updateStats.bind(this);
    this.previousStats = null;
};

oop.inherits(Worker, Mirror);

(function() {
    
    this.updateStats = function(){
        var value = this.doc.getValue();
        var stats = getStats(value);
        json = JSON.stringify(stats);
        if(json == this.previousStats){
            return
        }
        this.previousStats = json
        this.sender.emit("cssstats", stats);
        this.statsTimeout = 0;
    }
    
    this.onUpdate = function() {
        if(this.statsTimeout){
            clearTimeout(this.statsTimeout);
        }
        this.statsTimeout = setTimeout(this.updateStats, this.previousStats==null?600:6000);
    };
    
}).call(Worker.prototype);

});