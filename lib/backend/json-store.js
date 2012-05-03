

// Skeleton:bin:Skeleton.js

(function(global, undefined) {
	var fs = require("fs");
	var path = require("path");
	var util   = require("util");
	var Store = function(){};
	Store.file = __dirname+"/db.json";
	Store.save = function(data) {
		var writeReady = JSON.stringify(data);
		fs.writeFileSync(Store.file, writeReady, "utf8");
	}
	Store.read = function() {
		var string = fs.readFileSync(Store.file, "utf8");
		var data = JSON.parse(string);
		return data;
	}
	Store.removeItem = function(obj, item, callback) {
		delete obj[item];
		callback();	
	};
	module.exports = Store;
})(global);

/* EOF */