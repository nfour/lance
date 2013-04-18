```
       __                     
      / /___ _____  ________  
     / / __ `/ __ \/ ___/ _ \ 
    / / /_/ / / / / /__/  __/ 
   /_/\__/_/_/ /_/\___/\___/            
   
```
Lance, another flavor on a minimal node web framework.
```coffee
cfg   = require './cfg'
lance = require 'lance'

lance cfg

server = lance.createServer()
server.listen '1337'

lance.router.GET '/:page(about|contact)', 'paging', (req, res) -> res.serve "pages/#{req.route.path.page}"
lance.router.GET '/', 'home', (req, res) -> res.serve 'home'
```
Lance contains functionality for:
- Routing and request parsing
- Automated Stylus, CoffeeScript, css, js rendering, watching, merging, minifying
- Templating

Basically, web server essentials.

Additionally; error handling, compression, utility functions, cookies

### API
Lance is governed by a single config object that you feed it on initialization.
The idea is to supply said config then to barely have to touch Lance again.

```coffee
cfg = require './cfg/lance' # Exports the config object
lance cfg # Initiated
```

See `/cfg/lance.coffee` for the default config.

Lance makes a request's response functionality avaliable via the extension of the `req` and `res` http variables supplied to new requests. `res` and `req` does not need to be passed to any of these functions.

```coffee
# Imagine a url path: '/about?foo=bar'
# Matching route pattern: '/:page(about|contact)' (as defined in the example above)

### request extensions ###

req.res   = res
req.route = {
    path     : { page: 'about' }
    splats   : []
    name     : 'paging'
    callback : ->
    pattern  : ''
}

# The fallback callback for all routes
req.callback = ->

req.GET  = { foo: 'bar' }
req.POST = {}

### response extensions ###

res.req = req

# A function for serving a template or body
# Default values for the optionsObject are:
optionsObject = {
    code     : 200
    headers  : { 'content-type': 'text/html; charset=utf-8' }
    encoding : 'utf8'
    body     : ''
    view     : ''
    template : '' # An alias to 'view'. Either is valid
    data     : {} # contains data that will passed to templates/views
}
res.serve = (optionsObject_or_viewPathString) ->

# Serves an object or string as json with the correct headers
res.serve.json = (jsonObject_or_jsonString) ->

# Redirects to the specified path
res.serve.redirect = (pathString) ->

# Serves a plaintext page with the code and its corresponding description (as body) as defined in httpcodes.coffee
res.serve.code = (httpCode, [headers], [body]) ->

# A function to compress a body according to request headers, returning it in a callback
# This is also called automatically if lance.cfg.compress is true. Default is false
res.compress = (body, callback) ->

# A shortcut to serve the response, bypassing templating (it's called by res.serve eventually)
# Default values for the optionsObject are:
optionsObject = {
    code     : 200
    headers  : { 'content-type': 'text/html; charset=utf-8' }
    encoding : 'utf8'
    body     : ''
}
res.respond = (optionsObject) ->

```

Write `console.log lance` to show all exposed properties, as prototyping isnt used.

Other than that, just look through the code yourself. While it's not commented, considering the verbosity of CoffeeScript and the variable name choices, I'd say it's mostly self explanitory.

For templating, ECT is supported. Consolodate.js may be a good idea to support should anyone but myself decide to use this code.

And that's about it.








