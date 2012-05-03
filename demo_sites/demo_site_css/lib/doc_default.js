(function() {
  this.rotateBanners = function(images) {
    var image, index, rotate, _i, _len;
    index = -1;
    for (_i = 0, _len = images.length; _i < _len; _i++) {
      image = images[_i];
      document.createElement("img").src = image;
    }
    rotate = function() {
      if (++index >= images.length) {
        index = 0;
      }
      document.getElementById("header").style["backgroundImage"] = "url(" + images[index] + ")";
      return setTimeout(rotate, 10000);
    };
    return rotate();
  };
}).call(this);
