origin = '#origin'

return alert 'Instead of clicking this link add it to your bookmarks and click the bookmark on your own site' if origin == window.location.origin

window.__styler_bookmarklet = true
parent = document.getElementsByTagName('head')[0] or document.body
script = document.createElement 'script'
script.setAttribute 'type', 'text/javascript'
script.setAttribute 'src',  origin + '/styler.js'
parent.appendChild script
