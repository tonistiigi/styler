define(function(require, exports, module) {

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
});