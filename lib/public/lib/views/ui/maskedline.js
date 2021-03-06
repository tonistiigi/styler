// Generated by CoffeeScript 1.7.1
(function() {
  define(function(require, exports, module) {
    var MaskedLine;
    MaskedLine = Backbone.View.extend({
      RANGE: .25,
      FRICTION: .90,
      SPEED: .5,
      TOPSPEED: 3,
      initialize: function() {
        _.bindAll(this, "onenterframe", "onmousemove", "onmouseover", "onmouseout");
        $(this.el).addClass("maskedline");
        this.scrollable = this.el.firstChild;
        this.inner = this.scrollable.firstChild;
        $(this.inner).addClass("inner");
        $(this.scrollable).bind("mouseover", this.onmouseover);
        $(this.scrollable).bind("mouseout", this.onmouseout);
        this.xpos = 0;
        this.vx = 0;
        this.ax = 0;
        this.over = false;
        return this.offset = 0;
      },
      onenterframe: function() {
        var rate;
        if (this.outwidth <= this.inwidth) {
          return;
        }
        rate = 0;
        if (this.xpos < this.inwidth * this.RANGE) {
          rate = this.xpos / (this.inwidth * this.RANGE) - 1;
        } else if (this.xpos > this.inwidth - this.inwidth * this.RANGE) {
          rate = (this.xpos - this.inwidth + this.inwidth * this.RANGE) / (this.inwidth * this.RANGE);
        }
        this.ax = rate * this.SPEED;
        this.vx += this.ax;
        this.vx *= this.FRICTION;
        if (this.vx > this.TOPSPEED) {
          this.vx = this.TOPSPEED;
        }
        if (this.vx < -this.TOPSPEED) {
          this.vx = -this.TOPSPEED;
        }
        if (this.vx > 0 && this.vx < 0.01) {
          this.vx = 0;
        }
        if (this.vx < 0 && this.vx > -0.01) {
          this.vx = 0;
        }
        this.offset = this.inner.offsetLeft;
        this.offset -= this.vx;
        if (this.offset > 0) {
          this.offset = 0;
          this.vx = 0;
        } else if (this.offset < this.inwidth - this.outwidth) {
          this.offset = this.inwidth - this.outwidth;
          this.vx = 0;
        }
        return this.inner.style.left = this.offset + "px";
      },
      onmousemove: function(e) {
        return this.xpos = (e.offsetX || e.layerX) + this.offset;
      },
      onmouseover: function(e) {
        if (this.over) {
          return;
        }
        this.outwidth = this.inner.scrollWidth;
        this.inwidth = this.scrollable.offsetWidth;
        this.xpos = e.clientX - e.currentTarget.offsetLeft;
        $(this.scrollable).bind("mousemove", this.onmousemove);
        this.interval = setInterval(this.onenterframe, 35);
        $(this.el).addClass("overstate");
        $(this.el).removeClass("outstate");
        return this.over = true;
      },
      onmouseout: function(e) {
        var dx, dy;
        dx = e.offsetX || e.layerX;
        dy = e.offsetY || e.layerY;
        if (dx + this.offset > 0 && dx + this.offset < this.inwidth - 3 && dy > 0 && dy < 15) {
          return;
        }
        return this.reset();
      },
      reset: function() {
        $(this.scrollable).unbind("mousemove", this.onmousemove);
        clearInterval(this.interval);
        $(this.el).removeClass("overstate");
        $(this.el).addClass("outstate");
        _.delay((function(_this) {
          return function() {
            return _this.inner.style['left'] = "0px";
          };
        })(this));
        this.vx = 0;
        return this.over = false;
      }
    });
    return module.exports = MaskedLine;
  });

}).call(this);
