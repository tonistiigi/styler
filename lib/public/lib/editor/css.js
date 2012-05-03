/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Ajax.org Code Editor (ACE).
 *
 * The Initial Developer of the Original Code is
 * Ajax.org B.V.
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *      Fabian Jakobs <fabian AT ajax DOT org>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

define(function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextMode = require("ace/mode/text").Mode;
var Tokenizer = require("ace/tokenizer").Tokenizer;
var CssHighlightRules = require("ace/mode/css_highlight_rules").CssHighlightRules;
var MatchingBraceOutdent = require("ace/mode/matching_brace_outdent").MatchingBraceOutdent;
var WorkerClient = require("ace/worker/worker_client").WorkerClient;
var CstyleBehaviour = require("ace/mode/behaviour/cstyle").CstyleBehaviour;

var Mode = function() {
    this.$tokenizer = new Tokenizer(new CssHighlightRules().getRules());
    this.$outdent = new MatchingBraceOutdent();
    this.$behaviour = new CstyleBehaviour();
    
    this.$behaviour.add("semicolon", "insertion", function (state, action, editor, session, text) {
        
        if (text == "\n") {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            // Find what token we're inside.
            var tokens = session.getTokens(cursor.row, cursor.row)[0].tokens;
            isproperty = false;
            tokens.forEach(function(token){
               if(token.type == "support.type" || token.type=="constant.numeric" || token.type=="support.constant"){
                   isproperty = true;
               } 
            });
            if (isproperty && line.indexOf(":") != -1 && line.indexOf(";") == -1){
                var indent = this.getNextLineIndent(state, line.substring(0, line.length - 1), session.getTabString());
                return {text: ";\n" + indent};
            }
        }
        
    });
    
    app.Settings.bind("change:csslint", this.onCSSLintChange.bind(this));
    
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

        var match = line.match(/^.*\{\s*$/);
        if (match) {
            indent += tab;
        }

        return indent;
    };

    this.checkOutdent = function(state, line, input) {
        return this.$outdent.checkOutdent(line, input);
    };

    this.autoOutdent = function(state, doc, row) {
        this.$outdent.autoOutdent(doc, row);
    };
    
    this.initWorker = function(worker) {
        this.$worker = worker;
        this.onCSSLintChange();
    };
    
    this.onCSSLintChange = function() {
        if(this.$worker) {
            this.$worker.emit("csslintconf", {data:app.Settings.get("csslint")});
        }
    };
    
    this.createWorker = function(session) {
        var worker = new WorkerClient(["ace"], "build/worker-css.js", (module.packaged ? '' : '/') + "lib/editor/css_worker", "Worker");
        this.initWorker(worker);
        worker.attachToDocument(session.getDocument());
        
        var mode = this;
        worker.on("outline", function(e) {
            if(mode._outlineManager)
                mode._outlineManager.setOutline(e.data);
        });
        worker.on("cssstats", function(e) {
            session._emit("stats", e.data);
        });
        
        worker.on("csslint", function(e) {
            var errors = [];
            e.data.forEach(function(message) {
                //console.log(message);
                errors.push({
                    row: message.line - 1,
                    column: message.col - 1,
                    text: message.message,
                    type: message.type,
                    lint: message
                });
            });
            
            session.setAnnotations(errors);
        });
        return worker;
    };

}).call(Mode.prototype);

exports.Mode = Mode;

});
