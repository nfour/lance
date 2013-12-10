```
       __                     
      / /___ _____  ________  
     / / __ `/ __ \/ ___/ _ \ 
    / / /_/ / / / / /__/  __/ 
   /_/\__/_/_/ /_/\___/\___/            
   
```
Lance, another flavor on a minimal node web framework.
```coffee
cfg   = require('./cfg')
lance = require('lance')

lance(cfg) # Initiates Lance with the config object

# Starts the server and listens on previously configured port/socket
# Depending on config, will start either cluster or normal server
lance.start()

lance.router.GET('/:page(about|contact)', 'paging', (req, res) ->
    res.serve "pages/#{req.route.path.page}"
)

lance.router.GET('*', (req, res) ->
    res.serve.code 400
)

lance.on('listening',->
    console.log 'listening!'
)
```
Lance handles:
- Routing
- Request parsing
- Cookies
- Templating (CSS, JS, Stylus, CoffeeScript, ECT)
- Automation of finding, rendering, watching, merging and minifying templating assets

Basically, web server basics.
Additionally; error handling, compression, utility functions, while being fast.

### API
Lance is governed by a single config object that you feed it on initialization.
The idea is to supply said config then to barely have to touch Lance again beyond defining routing and starting the server.

```coffee
cfg = require('./cfg/lance') # Exports the config object
lance(cfg) # Initiated
```

See `/cfg.coffee` for the default config.

Lance makes a request's response functionality avaliable via the extension of the `req` and `res` http variables supplied to new requests. `res` and `req` does not need to be passed to any of these functions.

```coffee
# Imagine a url path: '/about?foo=bar'
# Matching route pattern: '/:page(about|contact)' (as defined in the example above)

### request extensions ###

req.res     = res
req.cookies = [Cookies Object]
req.route   = {
    path     : { page: 'about' }
    splats   : []
    name     : 'paging'
    callback : ->
    pattern  : '/:page(about|contact)'
}

# The fallback callback for all routes
req.callback = ->

req.GET  = { foo: 'bar' }
req.POST = {}

### response extensions ###

res.req     = req
res.cookies = [Cookies Object]

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

### Events

All events contain appropriate modifiable objects for arguments. You can change properties to modify events.


- `respond` with `(options Object) ->`
- `serve` Right after res.serve is called. `(options Object) ->`
- `serve.json`, `serve.redirect`, `serve.code` Same as above, but with `(arguments Object) ->`
- `request` with `(res Object, req Object) ->`
- `listening` On server listening event

```coffee

lance.on('serve', (options) ->
    if options.data.goHome
        options.view = 'home'
)
```

In the above, the serve event still hasnt actually rendered anything thus the view can be changed.