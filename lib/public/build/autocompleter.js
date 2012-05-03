(function() {

  define('lib/editor/autocompleter', ['require', 'exports', 'module' , 'lib/propertycompletions'], function(require, exports, module) {
    var PropertyCompletions, addProperty, complete, completeProperty, completePseudo, completeSelector, properties, propertiesBase, propertiesBaseMoz, propertiesBaseMozWebkit, propertiesBaseMs, propertiesBaseO, propertiesBaseWebkit, propertiesStylus, pseudoClasses;
    PropertyCompletions = require("lib/propertycompletions");
    completeSelector = function(isStylus, selector, parent, offset, cb) {
      var before, c, found, p, parentSelectors, part, parts, selectorAfter, selectorBefore, _i, _j, _len, _len2;
      if (selector.length !== offset && selector[offset] !== " ") return cb(null);
      before = selector.substr(0, offset);
      parts = selector.split(" ");
      selectorBefore = [];
      selectorAfter = [];
      c = 0;
      found = false;
      for (_i = 0, _len = parts.length; _i < _len; _i++) {
        part = parts[_i];
        if (found) {
          selectorAfter.push(part);
        } else {
          c += part.length + 1;
        }
        if (c <= offset) {
          selectorBefore.push(part);
        } else if (!found) {
          selectorBefore = (selectorBefore.join(" ")).trim();
          offset -= c - part.length - 1;
          found = true;
          selector = part;
        }
      }
      selectorAfter = (selectorAfter.join(" ")).trim();
      parentSelectors = [];
      for (_j = 0, _len2 = parent.length; _j < _len2; _j++) {
        p = parent[_j];
        if (selectorBefore) {
          if (selectorBefore.indexOf("&") !== -1) {
            parentSelectors.push(selectorBefore.replace("&", p));
          } else {
            parentSelectors.push(p + " " + selectorBefore);
          }
        } else {
          parentSelectors.push(p);
        }
      }
      return app.console.callRemote("findElementMatches", {
        selector: selector,
        parent: parentSelectors,
        offset: offset,
        after: selectorAfter
      }, function(resp) {
        return cb({
          items: _.map(resp.results.sort(), function(value) {
            return {
              value: value
            };
          }),
          offset: offset
        });
      });
    };
    propertiesBase = "alignment-baseline|background|background-attachment|background-clip|background-color|background-image|background-origin|background-position|background-repeat|background-size|baseline-shift|border|border-color|border-width|border-style|border-bottom|border-bottom-color|border-bottom-left-radius|border-bottom-right-radius|border-bottom-style|border-bottom-width|border-collapse|border-image-outset|border-image-repeat|border-image-slice|border-image-source|border-image-width|border-left|border-left-color|border-left-style|border-left-width|border-radius|border-right|border-right-color|border-right-style|border-right-width|border-spacing|border-top|border-top-color|border-top-left-radius|border-top-right-radius|border-top-style|border-top-width|bottom|box-shadow|box-sizing|caption-side|clear|clip|clip-path|clip-rule|color|color-interpolation|color-interpolation-filters|color-rendering|content|counter-increment|counter-reset|cursor|direction|display|dominant-baseline|empty-cells|fill|fill-opacity|fill-rule|filter|float|flood-color|flood-opacity|font|font-family|font-size|font-size-adjust|font-stretch|font-style|font-variant|font-weight|glyph-orientation-horizontal|glyph-orientation-vertical|height|image-rendering|ime-mode|kerning|left|letter-spacing|lighting-color|line-height|list-style|list-style-image|list-style-position|list-style-type|margin|margin-bottom|margin-left|margin-right|margin-top|marker|marker-end|marker-mid|marker-offset|marker-start|mask|max-height|max-width|min-height|min-width|opacity|orphans|outline-color|outline-offset|outline-style|outline-width|overflow|overflow-x|overflow-y|padding|padding-bottom|padding-left|padding-right|padding-top|page-break-after|page-break-before|page-break-inside|pointer-events|position|quotes|resize|right|ruby-align|ruby-overhang|ruby-position|shape-rendering|speak|stop-color|stop-opacity|stroke|stroke-dasharray|stroke-dashoffset|stroke-linecap|stroke-linejoin|stroke-miterlimit|stroke-opacity|stroke-width|table-layout|text-align|text-anchor|text-decoration|text-indent|text-justify-trim|text-kashida|text-overflow|text-rendering|text-shadow|text-transform|top|unicode-bidi|vector-effect|vertical-align|visibility|white-space|widows|width|word-break|word-spacing|word-wrap|z-index|zoom|marks";
    propertiesBaseMozWebkit = "animation|animation-delay|animation-direction|animation-duration|animation-fill-mode|animation-iteration-count|animation-name|animation-play-state|animation-timing-function|appearance|backface-visibility|border-image|box-align|box-direction|box-flex|box-ordinal-group|box-orient|box-pack|column-count|column-gap|column-rule-color|column-rule-style|column-rule-width|column-width|hyphens|perspective|perspective-origin|transform|transform-origin|transition|transition-delay|transition-duration|transition-property|transition-timing-function|user-modify|user-select";
    propertiesBaseWebkit = "background-inline-policy|binding|border-bottom-colors|border-left-colors|border-right-colors|border-top-colors|box-sizing|column-rule|float-edge|font-feature-settings|font-language-override|force-broken-image-icon|image-region|orient|outline-radius|outline-radius-bottomleft|outline-radius-bottomright|outline-radius-topleft|outline-radius-topright|stack-sizing|tab-size|text-blink|text-decoration-color|text-decoration-line|text-decoration-style|user-focus|user-input|window-shadow";
    propertiesBaseMoz = "background-clip|background-composite|background-origin|background-size|border-fit|border-horizontal-spacing|border-vertical-spacing|box-flex-group|box-lines|box-reflect|box-shadow|color-correction|column-break-after|column-break-before|column-break-inside|column-span|dashboard-region|flow-into|font-smoothing|highlight|hyphenate-character|hyphenate-limit-after|hyphenate-limit-before|hyphenate-limit-lines|line-box-contain|line-break|line-clamp|locale|margin-after-collapse|margin-before-collapse|marquee|marquee-direction|marquee-increment|marquee-repetition|marquee-style|mask|mask-attachment|mask-box-image|mask-box-image-outset|mask-box-image-repeat|mask-box-image-slice|mask-box-image-source|mask-box-image-width|mask-clip|mask-composite|mask-image|mask-origin|mask-position|mask-repeat|mask-size|nbsp-mode|region-break-after|region-break-before|region-break-inside|region-overflow|rtl-ordering|svg-shadow|tap-highlight-color|text-combine|text-decorations-in-effect|text-emphasis-color|text-emphasis-position|text-emphasis-style|text-fill-color|text-orientation|text-security|text-stroke-color|text-stroke-width|transform-style|user-drag|writing-mode";
    propertiesBaseMs = "accelerator|background-position-x|background-position-y|behavior|block-progression|filter|ime-mode|interpolation-mode|layout-flow|layout-grid|layout-grid-char|layout-grid-line|layout-grid-mode|layout-grid-type|line-break|overflow-x|overflow-y|scrollbar-3dlight-color|scrollbar-arrow-color|scrollbar-base-color|scrollbar-darkshadow-color|scrollbar-face-color|scrollbar-highlight-color|scrollbar-shadow-color|scrollbar-track-color|text-align-last|text-autospace|text-justify|text-kashida-space|text-overflow|text-size-adjust|text-underline-position|transform-origin-x|transform-origin-y|word-break|word-wrap|writing-mode|zoom";
    propertiesBaseO = "border-image|link|link-source|tab-size|table-baseline|transform|transform-origin|transition|transition-delay|transition-duration|transition-property|transition-timing-function";
    propertiesStylus = "no-wrap?|box-shadow|user-select|column-count|column-gap|column-rule|column-rule-color|column-rule-width|column-rule-style|column-width|background-size|transform|border-image|transition|transition-property|transition-duration|transition-timing-functions|transition-delay|backface-visibility|opacity|whitespace|box-sizing|box-orient|box-flex|box-flex-group|box-align|box-pack|box-direction|animation|animation-name|animation-duration|animation-delay|animation-iteration-count|animation-timing-function|animation-play-state|animation-fill-mode|border-image|hyphens|appearance|border-radius|reset-box-model?|reset-font?|reset-body?|reset-html5?|fixed|absolute|relative|clearfix?|box|@extends";
    properties = propertiesBase.split("|");
    addProperty = function(propStr, pfx) {
      var prop, _i, _len, _ref, _results;
      _ref = propStr.split("|");
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        _results.push(properties.push("-" + pfx + "-" + prop));
      }
      return _results;
    };
    addProperty(propertiesBaseMozWebkit, "webkit");
    addProperty(propertiesBaseMozWebkit, "moz");
    addProperty(propertiesBaseWebkit, "webkit");
    addProperty(propertiesBaseMoz, "moz");
    addProperty(propertiesBaseMs, "ms");
    addProperty(propertiesBaseO, "o");
    propertiesStylus = propertiesStylus.split("|");
    pseudoClasses = "hover|focus|active|link|visited||lang|first-child|last-child|first-line|first-letter|before|after".split("|");
    completeProperty = function(isStylus, property, offset, cb) {
      var filter, matches;
      property = property.toLowerCase();
      filter = function(p) {
        return p.length >= property.length && p.indexOf(property) === 0;
      };
      matches = _.filter(properties, filter);
      if (isStylus) matches = matches.concat(_.filter(propertiesStylus, filter));
      return cb({
        items: _.map(matches.sort(), function(m) {
          if (m[m.length - 1] === "?") {
            return {
              value: m.substr(0, m.length - 1)
            };
          } else {
            return {
              value: m,
              property: true
            };
          }
        }),
        offset: offset
      });
    };
    completePseudo = function(pseudo, offset, cb) {
      var matches;
      pseudo = pseudo.toLowerCase();
      matches = _.filter(pseudoClasses, function(p) {
        return p.length >= pseudo.length && p.indexOf(pseudo) === 0;
      });
      return cb({
        items: _.map(matches, function(m) {
          return {
            value: m
          };
        }),
        offset: offset
      });
    };
    complete = function(isStylus, req, cb) {
      switch (req.type) {
        case "selector":
          return completeSelector(isStylus, req.selector, req.parent, req.offset, cb);
        case "property":
          return completeProperty(isStylus, req.property, req.offset, cb);
        case "value":
          req.value = req.value.replace(/[\!;].*$/, "");
          if (req.offset > req.value.length) return cb(null);
          return PropertyCompletions.complete(isStylus, req.property, req.value, req.offset, cb);
        case "pseudo":
          return completePseudo(req.pseudo, req.offset, cb);
      }
    };
    exports.complete = complete;
    return exports;
  });

}).call(this);
(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = Array.prototype.slice;

  define('lib/propertycompletions', ['require', 'exports', 'module' , 'lib/utils'], function(require, exports, module) {
    var AnyCompleter, BaseCompleter, BgCompleter, BgLayerCompleter, ColorCompleter, ColorPickerDialogCompleter, ExtendedSelectorCompleter, FunctionCompleter, HexColorCompleter, ListCompleter, MultiCompleter, PathCompleter, QuotesCompleter, RgbColorCompleter, UnitCompleter, UrlCompleter, UsedFontCompleter, ValueCompleter, bgPositionXCompleter, bgPositionYCompleter, bgRepeatCompleter, bg_pos_compl, borderCompleter, clearEndSpaces, colorCompleter, combineUrl, complete, completions, fontCompleter, fontFamilyCompleter, getPart, imageCompleter, makeArrayCompleter, makeArrayCompleterSingle, parallel, shadow_compl, stylusCompletions, unitCompleter, unitCompleterAuto, unitCompleterInherit, unitCompleterInheritAuto, _ref;
    _ref = require('lib/utils'), parallel = _ref.parallel, combineUrl = _ref.combineUrl, getPart = _ref.getPart, clearEndSpaces = _ref.clearEndSpaces;
    BaseCompleter = (function() {

      function BaseCompleter() {}

      BaseCompleter.prototype._parseConf = function(conf) {
        var parts;
        parts = conf.split('|');
        parts = _.map(parts, function(p) {
          var name, priority, _ref2;
          _ref2 = p.split(','), name = _ref2[0], priority = _ref2[1];
          return {
            name: name,
            priority: parseInt(priority || 0)
          };
        });
        parts.sort(function(a, b) {
          if (a.priority > b.priority) {
            return -1;
          } else if (a.priority < b.priority) {
            return 1;
          } else if (a.name < b.name) {
            return -1;
          } else if (a.name > b.name) {
            return 1;
          } else {
            return 0;
          }
        });
        return _.map(parts, function(i) {
          return i.name;
        });
      };

      return BaseCompleter;

    })();
    ValueCompleter = (function(_super) {

      __extends(ValueCompleter, _super);

      function ValueCompleter(conf) {
        this.options = this._parseConf(conf);
      }

      ValueCompleter.prototype.complete = function(value, offset, format, cb) {
        var items;
        value = clearEndSpaces(value, offset);
        if (value.length !== offset) return cb();
        value = value.toLowerCase();
        items = _.filter(this.options, function(item) {
          return item.toLowerCase().indexOf(value) === 0;
        });
        return cb({
          items: _.map(items, function(i) {
            return {
              value: i,
              offset: offset
            };
          })
        });
      };

      ValueCompleter.prototype.matches = function(value) {
        var _ref2;
        return _ref2 = value.toLowerCase(), __indexOf.call(this.options, _ref2) >= 0;
      };

      return ValueCompleter;

    })(BaseCompleter);
    UnitCompleter = (function(_super) {

      __extends(UnitCompleter, _super);

      function UnitCompleter(conf) {
        this.options = this._parseConf(conf);
        this.regexp = new RegExp('^[0-9]+(' + (this.options.join('|')) + ')$', 'i');
      }

      UnitCompleter.prototype.complete = function(value, offset, format, cb) {
        var items, match, unit;
        if (value.length !== offset) return cb();
        match = value.match(/^-?[\.0-9]+/);
        if (!match || value === '0') return cb();
        unit = value.substr(match[0].length);
        items = _.filter(this.options, function(item) {
          return item.indexOf(unit) === 0;
        });
        return cb({
          items: _.map(items, function(i) {
            return {
              value: i,
              offset: offset - match[0].length
            };
          })
        });
      };

      UnitCompleter.prototype.matches = function(value) {
        return !!value.match(this.regexp);
      };

      return UnitCompleter;

    })(BaseCompleter);
    AnyCompleter = (function() {

      function AnyCompleter() {
        var subs;
        subs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.subs = [];
        _.each(subs, this.addSub, this);
      }

      AnyCompleter.prototype.addSub = function(sub) {
        if (sub.completer == null) {
          sub = {
            completer: sub
          };
        }
        if (!sub.empty) sub.empty = false;
        if (sub.completer) this.subs.push(sub);
        return this;
      };

      AnyCompleter.prototype.findCompleters = function() {
        return this.subs;
      };

      AnyCompleter.prototype.complete = function(value, offset, format, cb) {
        var items, subs,
          _this = this;
        subs = this.findCompleters(value);
        if (!(subs != null ? subs.length : void 0)) return cb([]);
        items = [];
        return parallel(subs, function(sub, done) {
          if (value.length === 0 && subs.length > 1 && !sub.empty) return done();
          return sub.completer.complete(value, offset, format, function(completions) {
            var i, _i, _len, _ref2;
            if (completions != null ? completions.items : void 0) {
              _ref2 = completions.items;
              for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                i = _ref2[_i];
                items.push(i);
              }
            }
            return done();
          });
        }, function() {
          return cb({
            items: _.uniq(items, false, function(i) {
              return i.value;
            })
          });
        });
      };

      AnyCompleter.prototype.matches = function(value) {
        var sub, _i, _len, _ref2;
        _ref2 = this.subs;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          sub = _ref2[_i];
          if (sub.completer.matches(value)) return true;
        }
        return false;
      };

      return AnyCompleter;

    })();
    MultiCompleter = (function() {

      function MultiCompleter() {
        var subs;
        subs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.separator = ' ';
        this.subs = [];
        _.each(subs, this.addSub, this);
      }

      MultiCompleter.prototype.addSub = function(sub) {
        if (sub.completer == null) {
          sub = {
            completer: sub
          };
        }
        if (!sub.limit) sub.limit = 100;
        if (!sub.empty) sub.empty = false;
        if (sub.completer) this.subs.push(sub);
        return this;
      };

      MultiCompleter.prototype.setSeparator = function(separator) {
        this.separator = separator;
        return this;
      };

      MultiCompleter.prototype.complete = function(value, offset, format, cb) {
        var active, completer;
        active = getPart(value, this.separator, offset);
        completer = this.findCompleter(active);
        if (!completer) return cb();
        return completer.complete(active.txt, active.offset, format, cb);
      };

      MultiCompleter.prototype.findCompleter = function(active) {
        var compl, i, part, sub, subs, _i, _j, _len, _len2, _len3, _ref2;
        subs = (function() {
          var _i, _len, _ref2, _results;
          _ref2 = this.subs;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            sub = _ref2[_i];
            _results.push(_.clone(sub));
          }
          return _results;
        }).call(this);
        _ref2 = active.parts;
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          part = _ref2[i];
          if ((active != null ? active.i : void 0) !== i) {
            for (_i = 0, _len2 = subs.length; _i < _len2; _i++) {
              sub = subs[_i];
              if (sub.limit > 0 && sub.completer.matches(part)) {
                sub.limit--;
                break;
              }
            }
          }
        }
        compl = new AnyCompleter;
        for (_j = 0, _len3 = subs.length; _j < _len3; _j++) {
          sub = subs[_j];
          if (sub.limit > 0) compl.addSub(sub);
        }
        return compl;
      };

      MultiCompleter.prototype.matches = function(value) {
        return false;
      };

      return MultiCompleter;

    })();
    ListCompleter = (function(_super) {

      __extends(ListCompleter, _super);

      function ListCompleter() {
        var subs;
        subs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.subs = subs;
        this.setSeparator(',');
      }

      ListCompleter.prototype.complete = function(value, offset, format, cb) {
        var active, compl,
          _this = this;
        active = getPart(value, this.separator, offset);
        if (!value.length) active.i = 0;
        compl = this.findCompleter(active);
        if (!(compl && (active.txt != null) && active.i < this.subs.length)) {
          return cb();
        }
        return typeof compl.complete === "function" ? compl.complete(active.txt, active.offset, format, function(completion) {
          var items;
          items = completion != null ? completion.items : void 0;
          if (!items) return cb();
          _.each(items, function(i) {
            var _ref2;
            if (!i.incomplete) {
              if (active.i < active.parts.length - 1) {
                if (i.cursor == null) i.cursor = 1;
                return i.incomplete = true;
              } else if (active.i < _this.subs.length) {
                if (i.cursor == null) {
                  i.sfx = ((_ref2 = i.sfx) != null ? _ref2 : i.sfx = '') + ', ';
                }
                return i.incomplete = true;
              }
            }
          });
          return cb({
            items: items
          });
        }) : void 0;
      };

      ListCompleter.prototype.findCompleter = function(active) {
        if ((active != null ? active.i : void 0) != null) {
          return this.subs[active.i];
        } else {
          return null;
        }
      };

      return ListCompleter;

    })(MultiCompleter);
    QuotesCompleter = (function(_super) {

      __extends(QuotesCompleter, _super);

      function QuotesCompleter(base) {
        this.base = base;
      }

      QuotesCompleter.prototype.complete = function(value, offset, format, cb) {
        var addQuote, quote, _ref2;
        addQuote = false;
        quote = '';
        if (_ref2 = value[0], __indexOf.call("'\"", _ref2) >= 0) {
          quote = value[0];
          value = value.substr(1);
          offset--;
          if (value.slice(-1)[0] === quote) {
            value = value.slice(0, -1);
          } else {
            addQuote = true;
          }
        }
        return this.base.complete(value, offset, format, function(completion) {
          var items;
          items = completion != null ? completion.items : void 0;
          if (!items) return cb();
          items = _.map(items, function(i) {
            var hasspace, padd, _addQuote, _pfx, _quote, _sfx;
            if (i.incomplete) return i;
            _quote = quote;
            _addQuote = addQuote;
            hasspace = !!i.value.match(/\s/);
            if (hasspace && !_quote) {
              _pfx = _quote = '"';
              _addQuote = true;
            }
            if (_quote) {
              _sfx = _quote;
              if (!_addQuote) padd = 1;
            }
            if (_pfx) {
              if (i.pfx != null) {
                i.pfx = _pfx + i.pfx;
              } else {
                i.pfx = _pfx;
              }
            }
            if (_sfx) {
              if (i.sfx != null) {
                i.sfx += _sfx;
              } else {
                i.sfx = _sfx;
              }
            }
            if (padd) {
              if (i.padd != null) {
                i.padd += _padd;
              } else {
                i.padd = padd;
              }
            }
            return i;
          });
          return cb({
            items: items
          });
        });
      };

      QuotesCompleter.prototype.matches = function(value) {
        var _ref2;
        if (_ref2 = value[0], __indexOf.call("'\"", _ref2) >= 0) {
          return value[0] === value.slice(-1)[0] && this.base.matches(value.substr(1, value.length - 2));
        } else {
          return this.base.matches(value);
        }
      };

      return QuotesCompleter;

    })(BaseCompleter);
    FunctionCompleter = (function(_super) {

      __extends(FunctionCompleter, _super);

      function FunctionCompleter(options) {
        this.options = options;
        this.regexp = new RegExp('^(' + (_.map(this.options, function(o) {
          return o.name;
        })).join('|') + ')\\(.*\\)$', 'i');
      }

      FunctionCompleter.prototype.complete = function(value, offset, format, cb) {
        var addParen, cursor, parenindex, res, sub, subval;
        value = value.toLowerCase();
        if (value.length === offset) {
          res = _.select(this.options, function(o) {
            return 0 === (o.name + '()').indexOf(value) && value.length <= o.name.length;
          });
          if (res.length) {
            return cb({
              items: _.map(res, function(o) {
                return {
                  value: o.name + '()',
                  offset: offset,
                  cursor: -1,
                  func: 1
                };
              })
            });
          }
        }
        parenindex = value.indexOf('(');
        if (!(parenindex > 0 && (sub = _.find(this.options, function(o) {
          return o.name === value.substr(0, parenindex);
        })))) {
          return cb();
        }
        addParen = true;
        cursor = 0;
        subval = value.substr(parenindex + 1);
        if (subval.slice(-1)[0] === ')') {
          subval = subval.slice(0, -1);
          addParen = false;
          cursor = 1;
        }
        offset -= parenindex + 1;
        return sub.completer.complete(subval, offset, format, function(completion) {
          var items;
          items = completion != null ? completion.items : void 0;
          if (!items) return cb();
          items = _.map(items, function(i) {
            if (!i.incomplete) {
              if (addParen) {
                if (i.sfx != null) {
                  i.sfx += ')';
                } else {
                  i.sfx = ')';
                }
              }
              if (cursor) {
                if (i.cursor != null) {
                  i.cursor += cursor;
                } else {
                  i.cursor = cursor;
                }
              }
            }
            return i;
          });
          return cb({
            items: items
          });
        });
      };

      FunctionCompleter.prototype.matches = function(value) {
        return !!(typeof value.match === "function" ? value.match(this.regexp) : void 0);
      };

      return FunctionCompleter;

    })(BaseCompleter);
    UrlCompleter = (function(_super) {

      __extends(UrlCompleter, _super);

      function UrlCompleter() {
        UrlCompleter.__super__.constructor.call(this, [
          {
            name: 'url',
            completer: new QuotesCompleter(new PathCompleter)
          }
        ]);
      }

      return UrlCompleter;

    })(FunctionCompleter);
    PathCompleter = (function(_super) {

      __extends(PathCompleter, _super);

      function PathCompleter() {
        this.regexp = /[a-z0-9-_\/\.]/i;
      }

      PathCompleter.prototype.complete = function(value, offset, format, cb) {
        var baseUrl, index, url, val;
        if (offset !== value.length) return cb();
        index = value.search(/([\(\/'"][^\(\/'"]*$)/);
        offset -= 1 + index;
        val = value.substr(index + 1);
        if (val.length && 0 === '..'.indexOf(val)) {
          return cb({
            items: [
              {
                value: '../',
                offset: offset,
                incomplete: 1
              }
            ]
          });
        }
        baseUrl = app.console.currentFile();
        url = combineUrl(baseUrl, value);
        if (!url) return cb();
        return app.console.callAPI('GetImgList', {
          url: url
        }, function(list) {
          var params;
          if (!list) return cb();
          params = {
            items: _.map(list, function(i) {
              var item;
              item = {
                value: i,
                offset: offset
              };
              if (i.slice(-1)[0] === '/') {
                item.incomplete = 1;
              } else {
                item.preview = url;
              }
              return item;
            })
          };
          return cb(params);
        });
      };

      return PathCompleter;

    })(BaseCompleter);
    UsedFontCompleter = (function(_super) {

      __extends(UsedFontCompleter, _super);

      function UsedFontCompleter() {
        UsedFontCompleter.__super__.constructor.apply(this, arguments);
      }

      UsedFontCompleter.prototype.complete = function(value, offset, format, cb) {
        var fonts, items, _ref2;
        value = value.toLowerCase();
        fonts = (_ref2 = app.stats) != null ? _ref2.fonts.items : void 0;
        if (!(fonts && value.length === offset)) return cb();
        items = _.select(fonts, function(f) {
          return -1 !== f.name.toLowerCase().indexOf(value);
        });
        items = _.sortBy(items, function(f) {
          return -f.count;
        });
        return cb({
          items: _.map(items, function(i) {
            return {
              value: i.name,
              offset: offset
            };
          })
        });
      };

      UsedFontCompleter.prototype.matches = function(value) {
        var fonts, _ref2;
        fonts = (_ref2 = app.stats) != null ? _ref2.fonts.items : void 0;
        value = value.toLowerCase();
        if (fonts) {
          return _.find(fonts, function(f) {
            return f.name.toLowerCase() === value;
          });
        }
        return false;
      };

      return UsedFontCompleter;

    })(BaseCompleter);
    ExtendedSelectorCompleter = (function(_super) {

      __extends(ExtendedSelectorCompleter, _super);

      function ExtendedSelectorCompleter() {}

      ExtendedSelectorCompleter.prototype.complete = function(value, offset, format, cb) {
        var cursor, line, lines, name, tab, val, _i, _len, _ref2;
        tab = app.console.editor.tabs.selectedTab();
        cursor = tab.session.selection.getCursor();
        lines = tab.contentManager.outlinelines;
        this.options = [];
        for (line in lines) {
          val = lines[line];
          if (line < cursor.row) {
            _ref2 = val.name;
            for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
              name = _ref2[_i];
              this.options.push(name);
            }
          }
        }
        return ExtendedSelectorCompleter.__super__.complete.call(this, value, offset, format, cb);
      };

      return ExtendedSelectorCompleter;

    })(ValueCompleter);
    HexColorCompleter = (function(_super) {

      __extends(HexColorCompleter, _super);

      function HexColorCompleter() {
        this.regexp = /^#[0-9a-f]{3,6}$/i;
      }

      HexColorCompleter.prototype.complete = function(value, offset, format, cb) {
        var items, stats, _ref2;
        value = value.toLowerCase();
        stats = (_ref2 = app.stats) != null ? _ref2.colors.items : void 0;
        if (!(stats && value.length === offset)) return cb([]);
        items = _.select(stats, function(c) {
          return c.hex && (-1 !== c.hex.indexOf(value)) && c.hex.length > value.length;
        });
        items = _.sortBy(items, function(c) {
          return c.count;
        });
        return cb({
          items: _.map(items, function(i) {
            return {
              value: i.hex,
              offset: offset,
              color: 1
            };
          })
        });
      };

      HexColorCompleter.prototype.matches = function(value) {
        return !!value.match(this.regexp);
      };

      return HexColorCompleter;

    })(BaseCompleter);
    RgbColorCompleter = (function(_super) {

      __extends(RgbColorCompleter, _super);

      function RgbColorCompleter() {
        this.regexp = /^rgba?\s*\([0-9\s\.%]{5,}\)$/i;
      }

      RgbColorCompleter.prototype.complete = function(value, offset, format, cb) {
        var a, b, g, items, mode_rgb, mode_rgba, padd, r, sep, stats, val, _ref2, _ref3;
        value = value.toLowerCase();
        stats = (_ref2 = app.stats) != null ? _ref2.colors.items : void 0;
        padd = 0;
        if (!(stats && value.length)) return cb();
        if (offset + 1 === value.length && value[value.length - 1] === ')') {
          value = value.substr(0, value.length - 1);
          padd = 1;
        }
        if (offset !== value.length) return cb();
        mode_rgb = 0 === 'rgb('.indexOf(value.substr(0, 4));
        mode_rgba = 0 === 'rgba('.indexOf(value.substr(0, 5));
        r = g = b = a = null;
        if (!(mode_rgb || mode_rgba)) return cb();
        val = value.replace(/^rgba?\s*\(\s*/i, '');
        while (val.length !== value.length && val.length) {
          r = (_ref3 = val.match(/^[0-9]+/)) != null ? _ref3[0] : void 0;
          if (!r) return cb();
          val = val.substr(r.length);
          if (!val.length) break;
          sep = (val.match(/^\s*,?\s*/))[0];
          if (!sep) return cb();
          val = val.substr(sep.length);
          if (!val.length) break;
          g = (val.match(/^[0-9]+/))[0];
          if (!g) return cb();
          val = val.substr(g.length);
          if (!val.length) break;
          sep = (val.match(/^\s*,?\s*/))[0];
          if (!sep) return cb();
          val = val.substr(sep.length);
          if (!val.length) break;
          b = (val.match(/^[0-9]+/))[0];
          if (!b) return cb();
          val = val.substr(b.length);
          if (!val.length) break;
          sep = (val.match(/^\s*,?\s*/))[0];
          if (!sep) return cb();
          val = val.substr(sep.length);
          if (!val.length) break;
          if (value[3] === 'a') {
            a = (val.match(/^[0-9\.]+/))[0];
            if (!a) return cb();
            val = val.substr(a.length);
            if (!val.length) return cb();
          }
          break;
        }
        items = _.select(stats, function(c) {
          return c.rgb && (r === null || 0 === c.rgb[0].toString().indexOf(r)) && (g === null || 0 === c.rgb[1].toString().indexOf(g)) && (b === null || 0 === c.rgb[2].toString().indexOf(b)) && (a === null || 0 === c.rgb[3].toString().indexOf(a));
        });
        items = _.sortBy(items, function(c) {
          return c.count;
        });
        return cb({
          items: _.map(items, function(i) {
            var rgba;
            rgba = value[3] === 'a' || i.rgb[3] !== 1;
            val = 'rgb';
            if (rgba) val += 'a';
            val += '(' + i.rgb[0] + ',' + i.rgb[1] + ',' + i.rgb[2];
            if (rgba) val += ',' + i.rgb[3];
            val += ')';
            return {
              value: val,
              offset: offset,
              color: 1,
              padd: padd
            };
          })
        });
      };

      RgbColorCompleter.prototype.matches = function(value) {
        return !!value.match(this.regexp);
      };

      return RgbColorCompleter;

    })(BaseCompleter);
    ColorPickerDialogCompleter = (function(_super) {

      __extends(ColorPickerDialogCompleter, _super);

      function ColorPickerDialogCompleter() {
        ColorPickerDialogCompleter.__super__.constructor.apply(this, arguments);
      }

      ColorPickerDialogCompleter.prototype.complete = function(value, offset, format, cb) {
        var _ref2;
        if (!(!value.length || value.match(/^#[a-f0-9]{0,6}$/i))) return cb(null);
        if (offset === value.length && ((_ref2 = value.length) === 4 || _ref2 === 7)) {
          return cb(null);
        }
        return cb({
          items: [
            {
              value: 'Open picker',
              offset: 0,
              exec: function(editor, coord) {
                var _ref3;
                return (_ref3 = editor.commands) != null ? _ref3.startColorPicker(false, coord) : void 0;
              }
            }
          ]
        });
      };

      ColorPickerDialogCompleter.prototype.matches = function() {
        return false;
      };

      return ColorPickerDialogCompleter;

    })(BaseCompleter);
    ColorCompleter = (function(_super) {

      __extends(ColorCompleter, _super);

      function ColorCompleter() {
        var colorchange;
        ColorCompleter.__super__.constructor.call(this);
        colorchange = new ListCompleter(this, new BaseCompleter);
        this.addSub(this.stylusFunctions = new FunctionCompleter([
          {
            name: 'darken',
            completer: colorchange
          }, {
            name: 'lighten',
            completer: colorchange
          }, {
            name: 'saturate',
            completer: colorchange
          }, {
            name: 'desaturate',
            completer: colorchange
          }, {
            name: 'fade-out',
            completer: colorchange
          }, {
            name: 'fade-in',
            completer: colorchange
          }, {
            name: 'spin',
            completer: colorchange
          }, {
            name: 'dark',
            completer: this
          }, {
            name: 'light',
            completer: this
          }
        ]));
        this.addSub({
          completer: new ColorPickerDialogCompleter(),
          empty: true
        });
        this.addSub({
          completer: new ValueCompleter('aliceblue|antiquewhite|aqua|aquamarine|azure|beige|bisque|black|blanchedalmond|blue|blueviolet|brown|burlywood|cadetblue|chartreuse|chocolate|coral|cornflowerblue|cornsilk|crimson|cyan|darkblue|darkcyan|darkgoldenrod|darkgray|darkgreen|darkgrey|darkkhaki|darkmagenta|darkolivegreen|darkorange|darkorchid|darkred|darksalmon|darkseagreen|darkslateblue|darkslategray|darkslategrey|darkturquoise|darkviolet|deeppink|deepskyblue|dimgray|dimgrey|dodgerblue|firebrick|floralwhite|forestgreen|fuchsia|gainsboro|ghostwhite|gold|goldenrod|gray|green|greenyellow|grey|honeydew|hotpink|indianred|indigo|ivory|khaki|lavender|lavenderblush|lawngreen|lemonchiffon|lightblue|lightcoral|lightcyan|lightgoldenrodyellow|lightgray|lightgreen|lightgrey|lightpink|lightsalmon|lightseagreen|lightskyblue|lightslategray|lightslategrey|lightsteelblue|lightyellow|lime|limegreen|linen|magenta|maroon|mediumaquamarine|mediumblue|mediumorchid|mediumpurple|mediumseagreen|mediumslateblue|mediumspringgreen|mediumturquoise|mediumvioletred|midnightblue|mintcream|mistyrose|moccasin|navajowhite|navy|oldlace|olive|olivedrab|orange|orangered|orchid|palegoldenrod|palegreen|paleturquoise|palevioletred|papayawhip|peachpuff|peru|pink|plum|powderblue|purple|red|rosybrown|royalblue|saddlebrown|salmon|sandybrown|seagreen|seashell|sienna|silver|skyblue|slateblue|slategray|slategrey|snow|springgreen|steelblue|tan|teal|thistle|tomato|turquoise|violet|wheat|white|whitesmoke|yellow|yellowgreen|transparent')
        });
        this.addSub({
          completer: new HexColorCompleter,
          empty: true
        });
        this.addSub(new RgbColorCompleter);
      }

      ColorCompleter.prototype.findCompleters = function() {
        var _this = this;
        if (this.format !== 'stylus') {
          return _.filter(this.subs, function(sub) {
            return sub.completer !== _this.stylusFunctions;
          });
        } else {
          return this.subs;
        }
      };

      ColorCompleter.prototype.complete = function(value, offset, format, cb) {
        this.format = format;
        return ColorCompleter.__super__.complete.call(this, value, offset, format, function(res) {
          return cb({
            items: _.map(res != null ? res.items : void 0, function(i) {
              if (!(i.func || i.exec)) i.color = 1;
              return i;
            })
          });
        });
      };

      return ColorCompleter;

    })(AnyCompleter);
    makeArrayCompleterSingle = function(base) {
      return new MultiCompleter().setSeparator(',').addSub({
        completer: new MultiCompleter().addSub({
          completer: base,
          limit: 1,
          empty: true
        }),
        empty: true
      });
    };
    makeArrayCompleter = function(base) {
      return new MultiCompleter().setSeparator(',').addSub({
        completer: base,
        empty: true
      });
    };
    unitCompleter = new UnitCompleter('px,10|mm,1|cm,1|in,2|pt,1|pc,1|%,5|em,3|ex,1|ch|rem|vh|vw|vm');
    unitCompleterInherit = new AnyCompleter(unitCompleter, new ValueCompleter('inherit'));
    unitCompleterInheritAuto = new AnyCompleter(unitCompleter, new ValueCompleter('inherit|auto'));
    unitCompleterAuto = new AnyCompleter(unitCompleter, new ValueCompleter('auto'));
    colorCompleter = new ColorCompleter();
    imageCompleter = new AnyCompleter().addSub({
      completer: new UrlCompleter(),
      empty: true
    }).addSub({
      completer: new ValueCompleter('none')
    });
    fontFamilyCompleter = new QuotesCompleter(new AnyCompleter().addSub({
      empty: true,
      completer: new UsedFontCompleter()
    }).addSub({
      empty: true,
      completer: new ValueCompleter('serif|sans-serif|cursive|fantasy|monospace|Georgia|Palatino Linotype|Book Antiqua|Palatino|Times New Roman|Times|Arial|Helvetica|Arial Black|Gadget|Comic Sans MS|Impact|Charcoal|Lucida Sans Unicode|Lucida Grande|Tahoma|Geneva|Trebuchet MS|Verdana')
    }));
    stylusCompletions = {};
    completions = {};
    completions['border-image-source'] = completions['list-style-image'] = imageCompleter;
    completions.color = completions['background-color'] = completions['border-color'] = completions['border-bottom-color'] = completions['border-top-color'] = completions['border-left-color'] = completions['border-right-color'] = completions['column-rule-color'] = completions['outline-color'] = completions['text-decoration-color'] = colorCompleter;
    completions.position = new ValueCompleter('absolute|fixed|inherit|relative|static');
    completions.display = new ValueCompleter('block|inline|inline-block|inline-table|list-item|none|table|table-caption|table-cell|table-column|table-column-group|table-header-group|table-footer-group|table-row|table-row-group');
    completions.float = new ValueCompleter('inherit|left|none|right');
    completions.clear = new ValueCompleter('both|inherit|left|none|right');
    completions.direction = new ValueCompleter('ltr|rtl|inherit');
    completions['unicode-bidi'] = new ValueCompleter('normal|embed|bidi-override|inherit');
    completions['box-sizing'] = new ValueCompleter('border-box|content-box|padding-box');
    completions['list-style-type'] = new ValueCompleter('disc|circle|square|decimal|decimal-leading-zero|lower-roman|upper-roman|lower-greek|lower-alpha|lower-latin|upper-alpha|upper-latin|armenian|georgian|hebrew|cjk-ideographic|hiragana|katakana|hiragana-iroha|katakana-iroha');
    completions['list-style-position'] = new ValueCompleter('inside|outside|inherit');
    completions['border-style'] = completions['border-bottom-style'] = completions['border-top-style'] = completions['border-left-style'] = completions['border-right-style'] = new ValueCompleter('none|hidden|dashed|dotted|double|groove|inset|outset|ridge|solid,10');
    completions['outline-style'] = new ValueCompleter('none|hidden|dashed|dotted|double|groove|inset|outset|ridge|solid,10|auto|inherit');
    completions['font-style'] = new ValueCompleter('normal|italic|oblique|inherit');
    completions['text-transform'] = new ValueCompleter('capitalize|uppercase|lowercase|none|inherit');
    completions.overflow = completions['overflow-x'] = completions['overflow-y'] = new ValueCompleter('visible|hidden|scroll|auto|inherit');
    completions['empty-cells'] = new ValueCompleter('show|hide|inherit');
    completions['font-variant'] = new ValueCompleter('normal|small-caps|inherit');
    completions['font-weight'] = new ValueCompleter('normal,2|bold,3|bolder|lighter|100|200|300|400|500|600|700|800|900|inherit');
    completions['font-stretch'] = new ValueCompleter('inherit|ultra-condensed|extra-condensed|condensed|semi-condensed|normal|semi-expanded|expanded|extra-expanded|ultra-expanded|wider|narrower');
    completions['font-size-adjust'] = new ValueCompleter('none|inherit');
    completions['font-size'] = new AnyCompleter(unitCompleter).addSub({
      completer: new ValueCompleter('xx-small|x-small|small,2|medium,3|large,1|x-large|xx-large|smaller|larger|inherit'),
      empty: true
    });
    completions['outline-width'] = completions['border-width'] = completions['border-top-width'] = completions['border-right-width'] = completions['border-bottom-width'] = completions['border-left-width'] = new AnyCompleter(unitCompleter, {
      completer: new ValueCompleter('thin,3|medium,2|thick,1|inherit'),
      empty: true
    });
    completions['width'] = completions['height'] = completions['left'] = completions['top'] = completions['right'] = completions['bottom'] = unitCompleterInheritAuto;
    completions['min-width'] = completions['min-height'] = completions['max-width'] = completions['max-height'] = new AnyCompleter(unitCompleter, new ValueCompleter('inherit|none'));
    completions['hyphens'] = new ValueCompleter('none|manual|auto');
    completions['image-rendering'] = new ValueCompleter('auto|inherit|optimizeSpeed|optimizeQuality|-moz-crisp-edges|-o-crisp-edges|-webkit-optimize-contrast');
    completions['letter-spacing'] = completions['line-height'] = new AnyCompleter(unitCompleter, {
      completer: new ValueCompleter('normal'),
      empty: true
    });
    completions['visibility'] = completions['backface-visibility'] = new ValueCompleter('visible,2|hidden,3|collapse|inherit');
    completions['vertical-align'] = new AnyCompleter(unitCompleter, new ValueCompleter('baseline|sub|super|text-top|text-bottom|middle,3|top,3|bottom,3|inherit'));
    completions['text-align'] = new ValueCompleter('left,4|center,4|right,4|justify,3|start|end|inherit');
    completions['white-space'] = new ValueCompleter('normal|pre|nowrap,3|pre-wrap|pre-line|inherit');
    completions['pointer-events'] = new ValueCompleter('auto|none,3|visiblePainted|visibleFill|visibleStroke|visible| painted|fill|stroke|all|inherit');
    completions['resize'] = new ValueCompleter('none|both|horizontal|vertical|inherit');
    completions['cursor'] = new ValueCompleter('auto|default|none|context-menu|help|pointer,3|progress|wait|cell| crosshair|text|vertical-text|alias|copy|move|no-drop|not-allowed|e-resize|n-resize|ne-resize|nw-resize|s-resize|se-resize|sw-resize|w-resize|ew-resize|ns-resize|nesw-resize|nwse-resize|col-resize|row-resize|all-scroll|inherit');
    completions['ime-mode'] = new ValueCompleter('auto|normal|active|inactive|disabled');
    completions['caption-side'] = new ValueCompleter('top|bottom|left|right|inherit');
    completions['border-collapse'] = new ValueCompleter('collapse|separate|inherit');
    completions['padding-top'] = completions['padding-right'] = completions['padding-bottom'] = completions['padding-left'] = completions['outline-offset'] = unitCompleterInherit;
    completions['margin-top'] = completions['margin-right'] = completions['margin-bottom'] = completions['margin-left'] = unitCompleterInheritAuto;
    completions['padding'] = new MultiCompleter().addSub({
      completer: unitCompleterInherit,
      limit: 4
    });
    completions['margin'] = new MultiCompleter().addSub({
      completer: unitCompleterInheritAuto,
      limit: 4
    });
    completions['marks'] = new AnyCompleter().addSub({
      completer: new ValueCompleter('none'),
      empty: true
    }).addSub({
      completer: new MultiCompleter({
        completer: new ValueCompleter('crop|cross'),
        limit: 2,
        empty: true
      }),
      empty: true
    });
    completions['text-decoration'] = new AnyCompleter().addSub({
      completer: new MultiCompleter({
        completer: new ValueCompleter('underline|overline|line-through|blink'),
        limit: 4,
        empty: true
      }),
      empty: true
    }).addSub({
      completer: new ValueCompleter('none|inherit'),
      empty: true
    });
    borderCompleter = new MultiCompleter().addSub({
      completer: completions['border-style'],
      limit: 1
    }).addSub({
      completer: completions['border-width'],
      limit: 1
    }).addSub({
      completer: colorCompleter,
      limit: 1
    });
    borderCompleter.findCompleter = function(active) {
      var completer, sub;
      completer = MultiCompleter.prototype.findCompleter.call(borderCompleter, active);
      if (completer.subs.length === 3) {
        sub = _.find(completer.subs, function(sub) {
          return sub.completer === completions['border-width'];
        });
        if (sub != null) sub.empty = true;
      } else if (completer.subs.length === 2) {
        sub = _.find(completer.subs, function(sub) {
          return sub.completer === completions['border-style'];
        });
        if (sub != null) sub.empty = true;
      }
      return completer;
    };
    completions['border'] = completions['border-top'] = completions['border-right'] = completions['border-bottom'] = completions['border-left'] = borderCompleter;
    completions['opacity'] = completions['orphans'] = new ValueCompleter('inherit', false);
    completions['border-radius'] = new MultiCompleter().addSub({
      completer: unitCompleter,
      limit: 8
    });
    completions['border-top-left-radius'] = completions['border-top-right-radius'] = completions['border-bottom-left-radius'] = completions['border-bottom-right-radius'] = new MultiCompleter().addSub({
      completer: unitCompleter,
      limit: 2
    });
    completions['background-attachment'] = makeArrayCompleterSingle(new ValueCompleter('scroll|fixed|local'));
    completions['background-image'] = makeArrayCompleterSingle(imageCompleter);
    bgRepeatCompleter = new ValueCompleter('repeat|repeat-x|repeat-y|no-repeat|space|round');
    completions['background-repeat'] = makeArrayCompleterSingle(bgRepeatCompleter);
    completions['background-clip'] = completions['background-origin'] = makeArrayCompleterSingle(completions['box-sizing']);
    completions['background-size'] = new AnyCompleter(new MultiCompleter().addSub({
      completer: unitCompleterAuto,
      limit: 2
    }), new ValueCompleter('contain|cover'));
    completions['background-size'].findCompleters = function(value) {
      if (value.match(/\b(contain|cover)\b/)) return null;
      return this.subs;
    };
    bgPositionXCompleter = new AnyCompleter(unitCompleter, {
      completer: new ValueCompleter('left|center|right'),
      empty: true
    });
    bgPositionYCompleter = new AnyCompleter(unitCompleter, {
      completer: new ValueCompleter('top|center|bottom'),
      empty: true
    });
    bg_pos_compl = new MultiCompleter();
    bg_pos_compl.findCompleter = function(active) {
      var i, index, part, _len, _ref2;
      if (active.txt == null) return null;
      index = 0;
      _ref2 = active.parts;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        part = _ref2[i];
        if (i === active.i) break;
        if (part.length) index++;
      }
      if (index === 0) {
        return bgPositionXCompleter;
      } else if (index === 1) {
        return bgPositionYCompleter;
      } else {
        return null;
      }
    };
    completions['background-position'] = makeArrayCompleter(bg_pos_compl);
    shadow_compl = new MultiCompleter().addSub({
      completer: unitCompleter,
      limit: 4
    }).addSub({
      completer: new ValueCompleter('inset'),
      limit: 1
    }).addSub({
      completer: colorCompleter,
      limit: 1
    });
    completions['box-shadow'] = new AnyCompleter(makeArrayCompleter(shadow_compl), new ValueCompleter('none'));
    BgLayerCompleter = (function(_super) {

      __extends(BgLayerCompleter, _super);

      function BgLayerCompleter(final) {
        this.final = final != null ? final : false;
        BgLayerCompleter.__super__.constructor.call(this);
        if (this.final) {
          this.addSub({
            completer: colorCompleter,
            limit: 1
          });
        }
        this.addSub({
          completer: imageCompleter,
          limit: 1,
          empty: true
        });
        this.addSub({
          completer: bgRepeatCompleter,
          limit: 1
        });
        this.addSub({
          completer: bgPositionXCompleter,
          limit: 1
        });
        this.addSub({
          completer: bgPositionYCompleter,
          limit: 1
        });
        this.addSub({
          completer: completions['background-size'],
          limit: 1
        });
        this.addSub({
          completer: completions['box-sizing'],
          limit: 1
        });
      }

      return BgLayerCompleter;

    })(MultiCompleter);
    BgCompleter = (function(_super) {

      __extends(BgCompleter, _super);

      function BgCompleter() {
        BgCompleter.__super__.constructor.call(this);
        this.setSeparator(',');
        this.layerCompleter = new BgLayerCompleter();
        this.finalLayerCompleter = new BgLayerCompleter(true);
      }

      BgCompleter.prototype.findCompleter = function(active) {
        if (active.i === active.parts.length - 1) {
          return this.finalLayerCompleter;
        } else {
          return this.layerCompleter;
        }
      };

      return BgCompleter;

    })(MultiCompleter);
    completions['background'] = new BgCompleter();
    completions['font-family'] = makeArrayCompleter(fontFamilyCompleter);
    fontCompleter = new MultiCompleter().setSeparator(',');
    fontCompleter.findCompleter = function(active) {
      var i, index, part, _len, _ref2;
      index = 0;
      _ref2 = active.parts;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        part = _ref2[i];
        if (i === active.i) break;
        if (part.length) index++;
      }
      if (index === 0) {
        return new MultiCompleter().addSub({
          completer: completions['font-style'],
          limit: 1
        }).addSub({
          completer: completions['font-weight'],
          limit: 1
        }).addSub({
          completer: completions['font-variant'],
          limit: 1
        }).addSub({
          completer: completions['font-size'],
          limit: 1
        }).addSub({
          completer: completions['line-height'],
          limit: 1
        }).addSub({
          completer: fontFamilyCompleter,
          limit: 1
        });
      } else {
        return fontFamilyCompleter;
      }
    };
    completions['font'] = fontCompleter;
    stylusCompletions['box'] = new ValueCompleter('horizontal|vertical');
    stylusCompletions['fixed'] = stylusCompletions['absolute'] = stylusCompletions['relative'] = new MultiCompleter().addSub({
      completer: new ValueCompleter('top|left|bottom|right'),
      limit: 2
    }).addSub({
      completer: unitCompleter,
      limit: 2
    });
    stylusCompletions['@extend'] = stylusCompletions['@extends'] = new ExtendedSelectorCompleter();
    complete = function(stylus, property, value, offset, cb) {
      var format;
      property = property.toLowerCase();
      format = stylus ? 'stylus' : 'css';
      if (stylus && stylusCompletions[property]) {
        return stylusCompletions[property].complete(value, offset, format, cb);
      } else if (completions[property]) {
        return completions[property].complete(value, offset, format, cb);
      } else {
        return cb();
      }
    };
    return module.exports = {
      complete: complete
    };
  });

}).call(this);
(function() {

  define('lib/views/ui/completer', ['require', 'exports', 'module' , 'ace/lib/event', 'ace/lib/useragent', 'ace/lib/keys', 'lib/utils', 'empty'], function(require, exports, module) {
    var COL_WIDTH, Completer, LINE_HEIGHT, keys, node, stopEvent, style, ua, _ref;
    stopEvent = require('ace/lib/event').stopEvent;
    ua = require('ace/lib/useragent');
    keys = require('ace/lib/keys');
    _ref = require('lib/utils'), node = _ref.node, style = _ref.style;
    require('empty');
    LINE_HEIGHT = 16;
    COL_WIDTH = ua.isGecko ? 7.2 : 7;
    Completer = Backbone.View.extend({
      id: 'completer',
      initialize: function() {
        _.bindAll(this, 'onKeyDown', 'onMouseWheel', 'onMouseDown');
        $(this.el).append(this.previewElement = node('div', {
          "class": 'preview'
        }));
        $(this.el).append(this.itemsElement = node('div', {
          "class": 'items'
        }));
        $(this.itemsElement).bind('mousedown', this.onMouseDown);
        this.reverse = false;
        return this.disable(true);
      },
      activate: function(tab, completions, row, col) {
        var editor, editorPos, items, pxcoord, top;
        this.tab = tab;
        items = completions.items;
        if (!(items != null ? items.length : void 0)) return this.disable();
        items = _.uniq(items, false, function(i) {
          return i.value;
        });
        this.offset = items[0].offset != null ? items[0].offset : completions.offset;
        if (items.length > 100) items = items.slice(0, 100);
        editor = this.tab.get('editor').editor;
        editorPos = editor.container.getBoundingClientRect();
        pxcoord = editor.renderer.textToScreenCoordinates(row, col - this.offset);
        top = pxcoord.pageY - editorPos.top;
        this.reverse = editorPos.height - top < 140;
        $(this.el).toggleClass('is-reverse', this.reverse).css(this.reverse ? {
          left: pxcoord.pageX - editorPos.left - 2,
          top: 'auto',
          bottom: editorPos.height - top
        } : {
          left: pxcoord.pageX - editorPos.left - 2,
          top: top + editor.renderer.lineHeight,
          bottom: 'auto'
        });
        if (!this.active) {
          $(this.el).show();
          window.addEventListener('keydown', this.onKeyDown, true);
          window.addEventListener('mousewheel', this.onMouseWheel, true);
        }
        this.active = true;
        this.keyDelta = 0;
        if (this.reverse) items = items.reverse();
        return this.setItems(items, this.offset);
      },
      disable: function(force) {
        if (force == null) force = false;
        if (this.active || force) {
          $(this.el).hide();
          this.active = false;
          this.selectedValue = '';
          window.removeEventListener('keydown', this.onKeyDown, true);
          return window.removeEventListener('mousewheel', this.onMouseWheel, true);
        }
      },
      setItems: function(items) {
        var el, fragment, i, item, offset;
        $(this.itemsElement).empty();
        this.selectedIndex = -1;
        this.items = [];
        fragment = document.createDocumentFragment();
        this.items = (function() {
          var _len, _results;
          _results = [];
          for (i = 0, _len = items.length; i < _len; i++) {
            item = items[i];
            offset = item.offset != null ? item.offset : this.offset;
            el = node('div', {
              "class": 'item'
            }, node('span', {
              "class": 'general'
            }, item.value.substr(0, offset)), node('span', {
              "class": 'unique'
            }, item.value.substr(offset)));
            if (item.color) {
              $(el).addClass('color');
              $(el).css({
                'border-color': item.value
              });
            }
            item.el = el;
            item.i = i;
            item.isSame = item.value.length <= offset;
            fragment.appendChild(el);
            _results.push(item);
          }
          return _results;
        }).call(this);
        if (this.items.length === 1 && this.items[0].isSame) return this.disable();
        $(this.itemsElement).append(fragment);
        style(this.el, {
          height: LINE_HEIGHT * Math.min(items.length, 5)
        });
        item = _.find(items, function(i) {
          return i.value === this.selectedValue;
        });
        this.select(item ? item.i : this.reverse ? items.length - 1 : 0);
        if (!this.items.length) return this.disable();
      },
      onMouseDown: function(e) {
        var item, itemEl;
        itemEl = $(e.target).closest('.item')[0];
        item = ((function() {
          var _i, _len, _ref2, _results;
          _ref2 = this.items;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            item = _ref2[_i];
            if (item.el === itemEl) _results.push(item);
          }
          return _results;
        }).call(this))[0];
        if (item) return this.completeItem(item);
      },
      select: function(index) {
        var item, _base;
        if (index === this.selectedIndex) return;
        if (this.selectedIndex !== -1) {
          item = this.items[this.selectedIndex];
          $(item.el).removeClass('selected');
        }
        this.selectedIndex = index;
        if (item = this.items[this.selectedIndex]) {
          $(item.el).addClass('selected');
          this.selectedValue = item.value;
          if (item.preview) {
            this.showPreview(item);
          } else if (this.isPreview) {
            this.hidePreview();
          }
          if (item.el.scrollIntoViewIfNeeded) {
            return item.el.scrollIntoViewIfNeeded(false);
          } else {
            return typeof (_base = item.el).scrollIntoView === "function" ? _base.scrollIntoView(false) : void 0;
          }
        }
      },
      completeItem: function(item) {
        if (item) {
          if (item.offset == null) item.offset = this.offset;
          this.tab.complete(item);
          return this.disable();
        }
      },
      showPreview: function(item) {
        var url,
          _this = this;
        this.isPreview = true;
        url = item.preview.split('/').slice(0, -1).join('/') + '/' + item.value;
        return require(['lib/views/ui/imagepreview'], function(ImagePreview) {
          return ImagePreview.getPreviewElement(url, 120, 75, function(err, el) {
            if (err) return;
            if (_this.isPreview) {
              return $(_this.previewElement).empty().append(el).show();
            }
          });
        });
      },
      hidePreview: function() {
        this.isPreview = false;
        return $(this.previewElement).hide().empty();
      },
      onMouseWheel: function() {
        return this.disable();
      },
      moveSelection: function(delta, e) {
        var directionDown, keyDelta;
        directionDown = delta > 0;
        keyDelta = directionDown ? -1 : 1;
        if ((directionDown ? this.selectedIndex < this.items.length - 1 : this.selectedIndex > 0)) {
          this.select(Math.max(0, Math.min(this.selectedIndex + delta, this.items.length - 1)));
        } else if (this.keyDelta !== keyDelta) {
          this.keyDelta = keyDelta;
        } else {
          this.disable();
        }
        return stopEvent(e);
      },
      onKeyDown: function(e) {
        var i, item, matches, offset, offset_, part, _i, _len, _ref2,
          _this = this;
        if (e.shiftKey) return;
        switch (keys[e.keyCode]) {
          case 'Down':
            return this.moveSelection(1, e);
          case 'Up':
            return this.moveSelection(-1, e);
          case 'PageDown':
            return this.moveSelection(10, e);
          case 'PageUp':
            return this.moveSelection(-10, e);
          case 'End':
            return this.moveSelection(1e3, e);
          case 'Home':
            return this.moveSelection(-1e3, e);
          case 'Return':
            if (item = this.items[this.selectedIndex]) {
              stopEvent(e);
              if (ua.isMozilla && item.exec) {
                return _.defer(function() {
                  return _this.completeItem(item);
                });
              } else {
                return this.completeItem(item);
              }
            }
            break;
          case 'Esc':
            this.disable();
            return stopEvent(e);
          case 'Tab':
            if (item = this.items[this.selectedIndex]) {
              if (this.items.length === 1) {
                this.completeItem(item);
              } else {
                offset = offset_ = item.offset ? item.offset : this.offset;
                while (true) {
                  offset_++;
                  part = this.items[this.selectedIndex].value.substr(0, offset_);
                  matches = true;
                  _ref2 = this.items;
                  for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                    i = _ref2[_i];
                    if (i.length < offset || part !== i.value.substr(0, offset_)) {
                      matches = false;
                      break;
                    }
                  }
                  if (!matches) break;
                }
                offset_--;
                if (offset_ > offset) {
                  this.tab.complete({
                    value: this.items[this.selectedIndex].value.substr(0, offset_),
                    offset: offset
                  });
                }
              }
            }
            return stopEvent(e);
        }
      }
    });
    return module.exports = Completer;
  });

}).call(this);
