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

define('lib/editor/css', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/tokenizer', 'ace/mode/css_highlight_rules', 'ace/mode/matching_brace_outdent', 'ace/worker/worker_client', 'ace/mode/behaviour/cstyle'], function(require, exports, module) {

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

define('ace/mode/css_highlight_rules', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/lib/lang', 'ace/mode/text_highlight_rules'], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var lang = require("../lib/lang");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var CssHighlightRules = function() {

    var properties = lang.arrayToMap(
        ("-moz-appearance|-moz-box-sizing|-webkit-box-sizing|-moz-outline-radius|-moz-transform|-webkit-transform|" +
        "appearance|azimuth|background-attachment|background-color|background-image|" +
        "background-origin|background-position|background-repeat|background|border-bottom-color|" +
        "border-bottom-style|border-bottom-width|border-bottom|border-collapse|" +
        "border-color|border-left-color|border-left-style|border-left-width|" +
        "border-left|border-right-color|border-right-style|border-right-width|" +
        "border-right|border-spacing|border-style|border-top-color|" +
        "border-top-style|border-top-width|border-top|border-width|border|" +
        "bottom|box-sizing|caption-side|clear|clip|color|content|counter-increment|" +
        "counter-reset|cue-after|cue-before|cue|cursor|direction|display|" +
        "elevation|empty-cells|float|font-family|font-size-adjust|font-size|" +
        "font-stretch|font-style|font-variant|font-weight|font|height|left|" +
        "letter-spacing|line-height|list-style-image|list-style-position|" +
        "list-style-type|list-style|margin-bottom|margin-left|margin-right|" +
        "margin-top|marker-offset|margin|marks|max-height|max-width|min-height|" +
        "min-width|-moz-border-radius|opacity|orphans|outline-color|outline-offset|outline-radius|" +
        "outline-style|outline-width|outline|overflow|overflow-x|overflow-y|padding-bottom|" +
        "padding-left|padding-right|padding-top|padding|page-break-after|" +
        "page-break-before|page-break-inside|page|pause-after|pause-before|" +
        "pause|pitch-range|pitch|play-during|pointer-events|position|quotes|resize|richness|right|" +
        "size|speak-header|speak-numeral|speak-punctuation|speech-rate|speak|" +
        "stress|table-layout|text-align|text-decoration|text-indent|" +
        "text-shadow|text-transform|top|transform|unicode-bidi|vertical-align|" +
        "visibility|voice-family|volume|white-space|widows|width|word-spacing|" +
        "z-index").split("|")
    );

    var functions = lang.arrayToMap(
        ("rgb|rgba|url|attr|counter|counters").split("|")
    );

    var constants = lang.arrayToMap(
        ("absolute|all-scroll|always|armenian|auto|baseline|below|bidi-override|" +
        "block|bold|bolder|border-box|both|bottom|break-all|break-word|capitalize|center|" +
        "char|circle|cjk-ideographic|col-resize|collapse|content-box|crosshair|dashed|" +
        "decimal-leading-zero|decimal|default|disabled|disc|" +
        "distribute-all-lines|distribute-letter|distribute-space|" +
        "distribute|dotted|double|e-resize|ellipsis|fixed|georgian|groove|" +
        "hand|hebrew|help|hidden|hiragana-iroha|hiragana|horizontal|" +
        "ideograph-alpha|ideograph-numeric|ideograph-parenthesis|" +
        "ideograph-space|inactive|inherit|inline-block|inline|inset|inside|" +
        "inter-ideograph|inter-word|italic|justify|katakana-iroha|katakana|" +
        "keep-all|left|lighter|line-edge|line-through|line|list-item|loose|" +
        "lower-alpha|lower-greek|lower-latin|lower-roman|lowercase|lr-tb|ltr|" +
        "medium|middle|move|n-resize|ne-resize|newspaper|no-drop|no-repeat|" +
        "nw-resize|none|normal|not-allowed|nowrap|oblique|outset|outside|" +
        "overline|pointer|progress|relative|repeat-x|repeat-y|repeat|right|" +
        "ridge|row-resize|rtl|s-resize|scroll|se-resize|separate|small-caps|" +
        "solid|square|static|strict|super|sw-resize|table-footer-group|" +
        "table-header-group|tb-rl|text-bottom|text-top|text|thick|thin|top|" +
        "transparent|underline|upper-alpha|upper-latin|upper-roman|uppercase|" +
        "vertical-ideographic|vertical-text|visible|w-resize|wait|whitespace|" +
        "zero").split("|")
    );

    var colors = lang.arrayToMap(
        ("aqua|black|blue|fuchsia|gray|green|lime|maroon|navy|olive|orange|" +
        "purple|red|silver|teal|white|yellow").split("|")
    );

    // regexp must not have capturing parentheses. Use (?:) instead.
    // regexps are ordered -> the first match is used

    var numRe = "\\-?(?:(?:[0-9]+)|(?:[0-9]*\\.[0-9]+))";

    var base_ruleset = [
        {
            token : "comment", // multi line comment
            merge : true,
            regex : "\\/\\*",
            next : "ruleset_comment"
        },{
            token : "string", // single line
            regex : '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'
        }, {
            token : "string", // single line
            regex : "['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"
        }, {
            token : "constant.numeric",
            regex : numRe + "(?:em|ex|px|cm|mm|in|pt|pc|deg|rad|grad|ms|s|hz|khz|%)"
        }, {
            token : "constant.numeric",  // hex6 color
            regex : "#[a-f0-9]{6}"
        }, {
            token : "constant.numeric", // hex3 color
            regex : "#[a-f0-9]{3}"
        }, {
            token : function(value) {
                if (properties.hasOwnProperty(value.toLowerCase())) {
                    return "support.type";
                }
                else if (functions.hasOwnProperty(value.toLowerCase())) {
                    return "support.function";
                }
                else if (constants.hasOwnProperty(value.toLowerCase())) {
                    return "support.constant";
                }
                else if (colors.hasOwnProperty(value.toLowerCase())) {
                    return "support.constant.color";
                }
                else {
                    return "text";
                }
            },
            regex : "\\-?[a-zA-Z_][a-zA-Z0-9_\\-]*"
        }
      ];

    var ruleset = lang.copyArray(base_ruleset);
    ruleset.unshift({
        token : "paren.rparen",
        regex : "\\}",
        next:   "start"
    });

    var media_ruleset = lang.copyArray( base_ruleset );
    media_ruleset.unshift({
        token : "paren.rparen",
        regex : "\\}",
        next:   "media"
    });

    var base_comment = [{
          token : "comment", // comment spanning whole line
          merge : true,
          regex : ".+"
    }];

    var comment = lang.copyArray(base_comment);
    comment.unshift({
          token : "comment", // closing comment
          regex : ".*?\\*\\/",
          next : "start"
    });

    var media_comment = lang.copyArray(base_comment);
    media_comment.unshift({
          token : "comment", // closing comment
          regex : ".*?\\*\\/",
          next : "media"
    });

    var ruleset_comment = lang.copyArray(base_comment);
    ruleset_comment.unshift({
          token : "comment", // closing comment
          regex : ".*?\\*\\/",
          next : "ruleset"
    });

    this.$rules = {
        "start" : [{
            token : "comment", // multi line comment
            merge : true,
            regex : "\\/\\*",
            next : "comment"
        }, {
            token: "paren.lparen",
            regex: "\\{",
            next:  "ruleset"
        }, {
            token: "string",
            regex: "@.*?{",
            next:  "media"
        },{
            token: "keyword",
            regex: "#[a-z0-9-_]+"
        },{
            token: "variable",
            regex: "\\.[a-z0-9-_]+"
        },{
            token: "string",
            regex: ":[a-z0-9-_]+"
        },{
            token: "constant",
            regex: "[a-z0-9-_]+"
        }],

        "media" : [ {
            token : "comment", // multi line comment
            merge : true,
            regex : "\\/\\*",
            next : "media_comment"
        }, {
            token: "paren.lparen",
            regex: "\\{",
            next:  "media_ruleset"
        },{
            token: "string",
            regex: "\\}",
            next:  "start"
        },{
            token: "keyword",
            regex: "#[a-z0-9-_]+"
        },{
            token: "variable",
            regex: "\\.[a-z0-9-_]+"
        },{
            token: "string",
            regex: ":[a-z0-9-_]+"
        },{
            token: "constant",
            regex: "[a-z0-9-_]+"
        }],

        "comment" : comment,

        "ruleset" : ruleset,
        "ruleset_comment" : ruleset_comment,

        "media_ruleset" : media_ruleset,
        "media_comment" : media_comment
    };
};

oop.inherits(CssHighlightRules, TextHighlightRules);

exports.CssHighlightRules = CssHighlightRules;

});
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

define('ace/mode/matching_brace_outdent', ['require', 'exports', 'module' , 'ace/range'], function(require, exports, module) {
"use strict";

var Range = require("../range").Range;

var MatchingBraceOutdent = function() {};

(function() {

    this.checkOutdent = function(line, input) {
        if (! /^\s+$/.test(line))
            return false;

        return /^\s*\}/.test(input);
    };

    this.autoOutdent = function(doc, row) {
        var line = doc.getLine(row);
        var match = line.match(/^(\s*\})/);

        if (!match) return 0;

        var column = match[1].length;
        var openBracePos = doc.findMatchingBracket({row: row, column: column});

        if (!openBracePos || openBracePos.row == row) return 0;

        var indent = this.$getIndent(doc.getLine(openBracePos.row));
        doc.replace(new Range(row, 0, row, column-1), indent);
    };

    this.$getIndent = function(line) {
        var match = line.match(/^(\s+)/);
        if (match) {
            return match[1];
        }

        return "";
    };

}).call(MatchingBraceOutdent.prototype);

exports.MatchingBraceOutdent = MatchingBraceOutdent;
});
/* vim:ts=4:sts=4:sw=4:
 * ***** BEGIN LICENSE BLOCK *****
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
 *      Chris Spencer <chris.ag.spencer AT googlemail DOT com>
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

define('ace/mode/behaviour/cstyle', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/behaviour'], function(require, exports, module) {
"use strict";

var oop = require("../../lib/oop");
var Behaviour = require('../behaviour').Behaviour;

var CstyleBehaviour = function () {

    this.add("braces", "insertion", function (state, action, editor, session, text) {
        if (text == '{') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "") {
                return {
                    text: '{' + selected + '}',
                    selection: false
                }
            } else {
                return {
                    text: '{}',
                    selection: [1, 1]
                }
            }
        } else if (text == '}') {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == '}') {
                var matching = session.$findOpeningBracket('}', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null) {
                    return {
                        text: '',
                        selection: [1, 1]
                    }
                }
            }
        } else if (text == "\n") {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == '}') {
                var openBracePos = session.findMatchingBracket({row: cursor.row, column: cursor.column + 1});
                if (!openBracePos)
                     return null;

                var indent = this.getNextLineIndent(state, line.substring(0, line.length - 1), session.getTabString());
                var next_indent = this.$getIndent(session.doc.getLine(openBracePos.row));

                return {
                    text: '\n' + indent + '\n' + next_indent,
                    selection: [1, indent.length, 1, indent.length]
                }
            }
        }
    });

    this.add("braces", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '{') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.end.column, range.end.column + 1);
            if (rightChar == '}') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("parens", "insertion", function (state, action, editor, session, text) {
        if (text == '(') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "") {
                return {
                    text: '(' + selected + ')',
                    selection: false
                }
            } else {
                return {
                    text: '()',
                    selection: [1, 1]
                }
            }
        } else if (text == ')') {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == ')') {
                var matching = session.$findOpeningBracket(')', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null) {
                    return {
                        text: '',
                        selection: [1, 1]
                    }
                }
            }
        }
    });

    this.add("parens", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '(') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == ')') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("string_dquotes", "insertion", function (state, action, editor, session, text) {
        if (text == '"') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "") {
                return {
                    text: '"' + selected + '"',
                    selection: false
                }
            } else {
                var cursor = editor.getCursorPosition();
                var line = session.doc.getLine(cursor.row);
                var leftChar = line.substring(cursor.column-1, cursor.column);

                // We're escaped.
                if (leftChar == '\\') {
                    return null;
                }

                // Find what token we're inside.
                var tokens = session.getTokens(selection.start.row, selection.start.row)[0].tokens;
                var col = 0, token;
                var quotepos = -1; // Track whether we're inside an open quote.

                for (var x = 0; x < tokens.length; x++) {
                    token = tokens[x];
                    if (token.type == "string") {
                      quotepos = -1;
                    } else if (quotepos < 0) {
                      quotepos = token.value.indexOf('"');
                    }
                    if ((token.value.length + col) > selection.start.column) {
                        break;
                    }
                    col += tokens[x].value.length;
                }

                // Try and be smart about when we auto insert.
                if (!token || (quotepos < 0 && token.type !== "comment" && (token.type !== "string" || ((selection.start.column !== token.value.length+col-1) && token.value.lastIndexOf('"') === token.value.length-1)))) {
                    return {
                        text: '""',
                        selection: [1,1]
                    }
                } else if (token && token.type === "string") {
                    // Ignore input and move right one if we're typing over the closing quote.
                    var rightChar = line.substring(cursor.column, cursor.column + 1);
                    if (rightChar == '"') {
                        return {
                            text: '',
                            selection: [1, 1]
                        }
                    }
                }
            }
        }
    });

    this.add("string_dquotes", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '"') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == '"') {
                range.end.column++;
                return range;
            }
        }
    });

}
oop.inherits(CstyleBehaviour, Behaviour);

exports.CstyleBehaviour = CstyleBehaviour;
});// Generated by CoffeeScript 1.6.1
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define('lib/editor/cssmanager', ['require', 'exports', 'module' , 'lib/utils'], function(require, exports, module) {
    var CSSManager, getPart;
    getPart = require("lib/utils").getPart;
    CSSManager = (function() {

      function CSSManager(tab) {
        var _this = this;
        this.tab = tab;
        this.complete = false;
        this.tab.session.getMode()._outlineManager = this;
        _.bindAll(this, "publish", "onPublishComplete");
        this.haschanged = true;
        this.tab.session.doc.on("change", function() {
          _this.haschanged = true;
          return setTimeout(_this.publish, 1);
        });
      }

      CSSManager.prototype.publish = function() {
        if (this.loading) {
          return;
        }
        if (this.haschanged) {
          this.haschanged = false;
          if (app.console.isLiveMode()) {
            this.loading = true;
            return app.console.callAPI("PublishChanges", {
              url: this.tab.get("url"),
              data: this.tab.session.getValue()
            }, this.onPublishComplete);
          }
        }
      };

      CSSManager.prototype.onPublishComplete = function() {
        this.loading = false;
        if (this.haschanged) {
          return setTimeout(this.loadOutline, 300);
        }
      };

      CSSManager.prototype.ruleForLine = function(lineno) {
        while (lineno > 0 && !this.outlinelines[lineno]) {
          lineno--;
        }
        if (lineno === 0 && !this.outlinelines[lineno]) {
          lineno = -1;
        }
        return lineno;
      };

      CSSManager.prototype.ruleForSelectorText = function(selectorText, index) {
        var child, i, _i, _ref;
        i = 0;
        selectorText = selectorText.toLowerCase();
        _ref = this.outlinelines;
        for (_i in _ref) {
          child = _ref[_i];
          if (__indexOf.call(child.selector, selectorText) >= 0) {
            if (i === index) {
              return child.line;
            } else {
              i++;
            }
          }
        }
        return -1;
      };

      CSSManager.prototype.rangeForRule = function(line) {
        var doc, leftcurly, row, start;
        start = line;
        doc = this.tab.session.doc;
        leftcurly = 0;
        while (true) {
          if (line > doc.getLength()) {
            break;
          }
          row = doc.getLine(line - 1).replace(/\/\*.*\*\//g, "");
          if ((row.indexOf("{")) !== -1) {
            leftcurly++;
          }
          if (leftcurly > 1) {
            line--;
            break;
          }
          if ((row.indexOf("}")) !== -1) {
            break;
          }
          line++;
        }
        return {
          start: start,
          end: line
        };
      };

      CSSManager.prototype.previousRule = function(rule) {
        while (rule >= 0 && !this.outlinelines[--rule]) {
          true;
        }
        return rule;
      };

      CSSManager.prototype.nextRule = function(rule) {
        while (rule <= this.tab.session.doc.getLength() && !this.outlinelines[++rule]) {
          true;
        }
        return rule;
      };

      CSSManager.prototype.selectorTextForRule = function(ruleid) {
        var _ref;
        return (_ref = this.outlinelines[ruleid]) != null ? _ref.selector.join(",") : void 0;
      };

      CSSManager.prototype.completionAtPosition = function(_arg) {
        var cc, column, doc, hasbrace, lbraceindex, line, part, parts, prefixpart, property, pseudomatch, rbraceindex, row, rr, selector, stmt, type, _ref, _ref1, _ref2;
        row = _arg.row, column = _arg.column;
        doc = this.tab.session.doc;
        type = 0;
        rr = row;
        cc = column;
        while (!type && rr >= 0) {
          line = doc.getLine(rr);
          rbraceindex = line.indexOf("}");
          if (rbraceindex !== -1 && rbraceindex < cc) {
            type = 1;
          }
          lbraceindex = line.indexOf("{");
          hasbrace = lbraceindex !== -1;
          if (hasbrace) {
            if (lbraceindex < cc) {
              type = 2;
            } else {
              type = 1;
            }
          } else if (this.outlinelines[rr + 1]) {
            type = 1;
          }
          rr--;
          cc = 1000;
        }
        if (rr < 0) {
          type = 1;
        }
        line = doc.getLine(row);
        if (type === 1) {
          line = line.replace(/\{.*$/, "");
          if (line[0] === '@') {
            parts = line.split(' ');
            if (column <= parts[0].length) {
              return {
                type: 'atrule',
                rule: parts[0],
                offset: column
              };
            } else {
              return {
                type: 'atrulevalue',
                rule: parts[0],
                value: line.substr(parts[0].length + 1),
                offset: column - parts[0].length - 1
              };
            }
          }
          selector = getPart(line, ",", column);
          if (!(selector != null ? (_ref = selector.txt) != null ? _ref.length : void 0 : void 0)) {
            return;
          }
          prefixpart = line.substr(0, column);
          pseudomatch = prefixpart.match(/:([a-z-]*)$/i);
          if (pseudomatch && (column > line.length - 1 || ((_ref1 = line[column + 1]) != null ? _ref1.match(/^\s$/) : void 0))) {
            return {
              type: "pseudo",
              pseudo: pseudomatch[1],
              offset: pseudomatch[1].length
            };
          }
          return {
            type: "selector",
            selector: selector.txt,
            parent: [""],
            offset: selector.offset
          };
        } else {
          stmt = getPart(line, "{", column);
          stmt = getPart(stmt.txt, "}", stmt.offset);
          stmt = getPart(stmt.txt, ";", stmt.offset);
          if (!(stmt != null ? (_ref2 = stmt.txt) != null ? _ref2.length : void 0 : void 0)) {
            return;
          }
          part = getPart(stmt.txt, ":", stmt.offset);
          if ((part != null ? part.txt : void 0) == null) {
            return;
          }
          if (part.i === 0) {
            if (part.txt.length > part.offset) {
              return null;
            }
            return {
              type: "property",
              offset: part.offset,
              property: part.txt
            };
          } else if (part.i === 1) {
            property = stmt.txt.split(":")[0].trim();
            return {
              type: "value",
              value: part.txt,
              property: property,
              offset: part.offset
            };
          }
        }
        return null;
      };

      CSSManager.prototype.setOutline = function(outline) {
        var item, _i, _len;
        this.outlinelines = {};
        for (_i = 0, _len = outline.length; _i < _len; _i++) {
          item = outline[_i];
          item.selector = item.selector.split(",");
          this.outlinelines[item.line] = item;
        }
        if (!this.complete) {
          this.complete = true;
          this.trigger("loaded");
        }
        return this.trigger("update");
      };

      return CSSManager;

    })();
    _.extend(CSSManager.prototype, Backbone.Events);
    return module.exports = CSSManager;
  });

}).call(this);
define('lib/editor/stylus', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/tokenizer', 'lib/editor/stylus_highlight_rules', 'ace/worker/worker_client'], function(require, exports, module) {

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
define('lib/editor/stylus_highlight_rules', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text_highlight_rules'], function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules;

var StylusHighlightRules = function() {
    // regexp must not have capturing parentheses. Use (?:) instead.
    // regexps are ordered -> the first match is used

    var numRe = "\\-?(?:(?:[0-9]+)|(?:[0-9]*\\.[0-9]+))";

    function ic(str) {
        var re = [];
        var chars = str.split("");
        for (var i=0; i<chars.length; i++) {
            re.push(
                "[",
                chars[i].toLowerCase(),
                chars[i].toUpperCase(),
                "]"
            );
        }
        return re.join("");
    }
    
    this.$rules =  {
        "start" : [
            {
                token : "comment", // multi line comment
                //merge : true,
                regex : "\\/\\*",
                next : "comment"
            },
            {
                token: "comment",
                regex: "\\/\\/.*"
            },
            {
                token: "keyword",
                regex: "@[-\\w]+"
            },
            {
                token: "variable",
                regex: "\\.[a-zA-Z][a-zA-Z0-9_-]*"
            },
            {
                token: "variable",
                regex: "(:+\\b)("+("after|before|first-child|first-letter|first-line|selection").split("|").map(ic).join("|")+")(\\b)"
            },
            {
                token: "variable",
                regex: "(:\\b)("+("active|hover|link|visited|focus").split("|").map(ic).join("|")+")(\\b)"
            },
            {
                token: "constant.numeric",
                regex: "#[a-fA-F0-9]{1,6}\\b"
            },
            {
                token: "variable",
                regex: "#[a-zA-Z][a-zA-Z0-9_-]*"
            },
            {
                token: "keyword",
                regex: "\\b(\\!important|for|in|return|true|false|null|if|else|unless|return)\\b"
            },
            {
                token : "string", // single line
                regex : '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'
            },
            {
                token : "string", // single line
                regex : "['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"
            },
            {
                token : "string", // single line
                regex : "[\\(](?:(?:\\\\.)|(?:[^'\\\\]))*?[\\)]"
            },
            {
                token : "constant.numeric",
                regex : numRe + ic("em")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("ex")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("px")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("cm")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("mm")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("in")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("pt")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("pc")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("deg")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("rad")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("grad")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("ms")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("s")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("hz")
            }, {
                token : "constant.numeric",
                regex : numRe + ic("khz")
            }, {
                token : "constant.numeric",
                regex : numRe + "%"
            }, {
                token : "constant.numeric",
                regex : numRe
            }
        ],
        "comment" : [
            {
                  token : "comment", // closing comment
                  regex : ".*?\\*\\/",
                  next : "start"
            }, 
            {
                token : "comment", // comment spanning whole line
                regex : ".+"
            }
        ]
    }

}

oop.inherits(StylusHighlightRules, TextHighlightRules);

exports.StylusHighlightRules = StylusHighlightRules;
});// Generated by CoffeeScript 1.6.1
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define('lib/editor/stylusmanager', ['require', 'exports', 'module' ], function(require, exports, module) {
    var StylusManager;
    StylusManager = (function() {

      function StylusManager(tab) {
        var _this = this;
        this.tab = tab;
        _.bindAll(this, "loadOutline", "onStylusOutline");
        this.complete = false;
        this.haschanged = true;
        this.tab.session.doc.on("change", function() {
          _this.haschanged = true;
          return setTimeout(_this.loadOutline, 300);
        });
        _.defer(this.loadOutline);
      }

      StylusManager.prototype.ruleForLine = function(lineno) {
        if (!this.outlinelines) {
          return -1;
        }
        while (!this.outlinelines[lineno] && lineno >= 0) {
          lineno--;
        }
        return lineno;
      };

      StylusManager.prototype.ruleForSelectorText = function(selectorText, index) {
        var child, i, _i, _ref;
        i = 0;
        _ref = this.outlinelines;
        for (_i in _ref) {
          child = _ref[_i];
          if (__indexOf.call(child.name, selectorText) >= 0) {
            if (i === index) {
              return child.line;
            } else {
              i++;
            }
          }
        }
        return -1;
      };

      StylusManager.prototype.rangeForRule = function(line) {
        var doc, firstindent, indent, lastindent, length, row, start;
        start = line;
        doc = this.tab.session.doc;
        length = doc.getLength();
        firstindent = lastindent = doc.getLine(line).match(/^\s*/)[0].length;
        while (true) {
          row = doc.getLine(line);
          line++;
          if (row === "" || this.outlinelines[line]) {
            line--;
            break;
          }
          indent = row.match(/^\s*/)[0].length;
          if (indent === row.length) {
            line--;
            break;
          }
          if (indent < lastindent || indent > lastindent && lastindent > firstindent) {
            break;
          }
        }
        return {
          start: start,
          end: line
        };
      };

      StylusManager.prototype.previousRule = function(rule) {
        while (rule >= 0 && !this.outlinelines[rule--]) {
          true;
        }
        return rule + 1;
      };

      StylusManager.prototype.nextRule = function(rule) {
        while (rule <= this.tab.session.doc.getLength() && !this.outlinelines[++rule]) {
          true;
        }
        return rule;
      };

      StylusManager.prototype.selectorTextForRule = function(ruleid) {
        var _ref;
        return (_ref = this.outlinelines[ruleid]) != null ? _ref.name.join(",") : void 0;
      };

      StylusManager.prototype.completionAtPosition = function(_arg) {
        var c, column, doc, firstword, forceSelector, ident, ident2, item, length, line, line2, m, parent, parts, prefixpart, pseudomatch, row, row2, selector, selectors, value, _i, _len, _ref, _ref1;
        row = _arg.row, column = _arg.column;
        doc = this.tab.session.doc;
        line = doc.getLine(row);
        firstword = (_ref = line.match(/\s*(.*?)(:|\s|$)/)) != null ? _ref[1] : void 0;
        forceSelector = row <= (this.firstline != null) || !line.match(/^\s+/);
        if (firstword) {
          if (forceSelector || (firstword.match(/[\.#&>|]/)) || firstword.match(/^(div|span|a|p|br|table|tbody|tr|td|th|li|ul|ol)\b/i)) {
            line = doc.getLine(row);
            if (line[0] === '@') {
              parts = line.split(' ');
              if (column <= parts[0].length) {
                return {
                  type: 'atrule',
                  rule: parts[0],
                  offset: column
                };
              } else {
                return {
                  type: 'atrulevalue',
                  rule: parts[0],
                  value: line.substr(parts[0].length + 1),
                  offset: column - parts[0].length - 1
                };
              }
            }
            selectors = line.split(",");
            ident = (line.match(/^\s*/))[0].length;
            if (ident > column) {
              return;
            }
            prefixpart = line.substr(0, column);
            pseudomatch = prefixpart.match(/:([a-z-]*)$/i);
            if (pseudomatch && (column > line.length - 1 || ((_ref1 = line[column + 1]) != null ? _ref1.match(/^\s$/) : void 0))) {
              return {
                type: "pseudo",
                pseudo: pseudomatch[1],
                offset: pseudomatch[1].length
              };
            }
            c = 0;
            for (_i = 0, _len = selectors.length; _i < _len; _i++) {
              selector = selectors[_i];
              c += selector.length + 1;
              if (!(c >= column)) {
                continue;
              }
            }
            column -= c - selector.length - 1;
            parent = [""];
            row2 = row;
            if (ident !== 0) {
              while (row2) {
                row2--;
                item = this.outlinelines[row2 + 1];
                if (item) {
                  line2 = doc.getLine(row2);
                  ident2 = (line2.match(/^\s*/))[0].length;
                  if (ident2 < ident) {
                    parent = item.name;
                    break;
                  }
                }
              }
            }
            return {
              type: "selector",
              selector: selector,
              parent: parent,
              offset: column
            };
          } else {
            m = line.match(/^(\s*)([^\s:]+)\s*:?\s*/);
            length = m[0].length;
            if (column < length || (length && column === length && m[0][length - 1] !== " ")) {
              if (column - m[1].length === m[2].length) {
                return {
                  type: "property",
                  offset: m[2].length,
                  property: m[2]
                };
              }
            } else {
              value = line.substr(m[0].length);
              return {
                type: "value",
                value: value,
                property: m[2],
                offset: column - length
              };
            }
          }
        }
        return null;
      };

      StylusManager.prototype.loadOutline = function() {
        if (this.loading) {
          return;
        }
        if (this.haschanged) {
          this.haschanged = false;
          this.loading = true;
          return app.console.callAPI("GetStylusOutline", {
            url: this.tab.get("url"),
            publish: app.console.isLiveMode(),
            data: this.tab.session.getValue()
          }, this.onStylusOutline);
        }
      };

      StylusManager.prototype.onStylusOutline = function(outline) {
        var iserr;
        iserr = !!outline.err;
        if (iserr) {
          this.tab.set({
            error: outline
          });
        } else {
          this.outline = outline;
          if (this.tab.get("error")) {
            this.tab.set({
              error: null
            });
          }
          this.outlinelines = {};
          this.firstline = null;
          this.parseOutline(this.outline);
        }
        if (!this.complete) {
          this.complete = true;
          this.trigger("loaded");
        }
        this.trigger("update");
        this.loading = false;
        if (this.haschanged) {
          return setTimeout(this.loadOutline, 300);
        }
      };

      StylusManager.prototype.parseOutline = function(outline) {
        var child, n, n1, n2, name, names, parentnames, _i, _j, _k, _len, _len1, _len2, _ref, _results;
        _ref = outline.child;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          names = child.name;
          if (child.ident) {
            continue;
          }
          parentnames = outline.name;
          if (!parentnames.length) {
            parentnames = [""];
          }
          n = [];
          for (_j = 0, _len1 = names.length; _j < _len1; _j++) {
            n1 = names[_j];
            name = n1.replace(/\s+/g, " ").trim().toLowerCase();
            for (_k = 0, _len2 = parentnames.length; _k < _len2; _k++) {
              n2 = parentnames[_k];
              if ((name.indexOf("&")) !== -1) {
                n.push(name.replace(/&/g, n2));
              } else {
                n.push((n2 + " " + name).trim());
              }
            }
          }
          child.name = n;
          if (this.firstline == null) {
            this.firstline = child.line;
          }
          this.outlinelines[child.line] = child;
          child.parent = outline;
          if (child.child) {
            _results.push(this.parseOutline(child));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return StylusManager;

    })();
    _.extend(StylusManager.prototype, Backbone.Events);
    return module.exports = StylusManager;
  });

}).call(this);
