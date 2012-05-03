({
    appDir: "lib/public",
    baseUrl: "./",
    dir: "lib/public_build",
    optimize : "none",
    paths: {
      'socket.io/socket.io': 'empty:',
      'underscore': 'vendor/underscore',
      'backbone': 'vendor/backbone',
      'app' : 'empty:',
      'jade' : 'empty:',
      'ace' : '../../support/ace/lib/ace',
      'vendor/jade': '../../node_modules/jade/runtime.min'
    },
    modules: [
        {
            name: "lib/views/main",
            exclude: ["underscore", "backbone", "vendor/jade", "app"]
        }
    ]
})