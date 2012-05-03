define(function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextMode = require("ace/mode/text").Mode;
var Tokenizer = require("ace/tokenizer").Tokenizer;
var StylusHighlightRules = require("lib/editor/stylus_highlight_rules").StylusHighlightRules;
var WorkerClient = require("ace/worker/worker_client").WorkerClient;

var Mode = function() {
    this.$tokenizer = new Tokenizer(new StylusHighlightRules().getRules());
};
oop.inherits(Mode, TextMode);

(function() {
    
    this.getNextLineIndent = function(state, line, tab) {
        var indent = this.$getIndent(line);

        // ignore braces in comments
        var tokens = this.$tokenizer.getLineTokens(line, state).tokens;
        if (tokens.length && tokens[tokens.length-1].type == "comment") {
            return indent;
        }
        
        var isselector = false;
        for (var i=0; i<tokens.length; i++) {
            if (tokens[i].type === "keyword" && tokens[i].value === "@extends") {
                break;
            }
            if (tokens[i].type === "variable") {
                isselector = true;
            }
        }
        if (isselector) {
            indent += tab;
        }

        return indent;
    };
/*
    this.checkOutdent = function(state, line, input) {
        return this.$outdent.checkOutdent(line, input);
    };

    this.autoOutdent = function(state, doc, row) {
        this.$outdent.autoOutdent(doc, row);
    };
*/

    this.createWorker = function(session) {
        var worker = new WorkerClient(["ace"], "build/worker-stylus.js", (module.packaged ? '' : '/') + "lib/editor/stylus_worker", "Worker");
        worker.attachToDocument(session.getDocument());
        
        worker.on("cssstats", function(e) {
            session._emit("stats", e.data);
        });
    };
   
}).call(Mode.prototype);

exports.Mode = Mode;
});
