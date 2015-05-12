# Lance
The alpha-strike web server with sane defaults.
A framework that aims to handle everything for you, automatically.

**API Stability**: `Unstable`

## Minimal API
- `new Lance( config )`
- `lance.initailize()`

**What just happened:**
- A Http server was started
- Compiled, minified, bundled and watched Stylus, CoffeeScript, CJSX, CSS, JS
	+ Saved to the static directory
- Populated the static asset directory at `./static`
	+ Assets like `img.png`, `robots.txt` are copied over with their preserved directory structure.
- Set up request routing
- Began serving static assets from `./static`
- Began utlizing a templating engine in `./views`
- Began parsing http requests; forms, file transfers

All parts of Lance can be utilized outside of the config. Lance always utilizes promises for async operations.

See **[./config.coffee](#)**, effectively an API reference.

### The minimal example:
```coffee
Lance = require 'lance'

lance = new Lance {
	routes: [
		[ "GET", '/:api(a|b|c|d)', (o) ->
				console.log 'ayyy' if o.route.api is 'a'
				o.serve { body: 'woo!' }
		]
	]
}

lance.initialize().then -> # Server is up!
```

### The full example:
```coffee

###
The directory structure:
/project/
	/static/
	/views/
		index.jade
		style.styl
		app.coffee
		/images/
			image.png
	
	server.coffee (this)
###

Lance = require 'lance'

lance = new Lance {
	server:
		host: '0.0.0.0'
		port: 1337
		static: './static' # Automatically intercepts and serves static content
	
	templater:
		findIn: './views'
		saveTo: './static'
		
		###
		Bundle up all Stylus/Css or Coffee/Js dependencies into a single file
		by utilizing Stylus and browserify.
		###
		bundle:
			# destination	: source
			"my/css/here.css": "style.styl"
			"app.js": "app.coffee"
			
		templater:
			ext: '.jade'
			engine: require 'jade'
}

# Routes can be defined after instantiation, outside of the config, too

lance.router.get '/:api(a|b|c|d)', (o) ->
	###
	`o` is a special options object containing request information in a pre-parsed manner. `o` is passed to all route requests in place of `req` and `res`.
	
	More info on this later.
	###
	
	if o.route.api is 'a'
		console.log 'ayyy'
	
	# This will resolve to our ./project/views/index.jade file
	o.template.view = 'index'
	
	###
	o.serve() serves a response based on either arguements passed to it or depending on properties in `o`.
	
	if `o.template.view` is set, the template will be rendered
	if `o.redirect` is set, a redirection will occur
	if neither are set, Lance serves JSON by default.
	
	You may also instead call `o.serveTemplate()`, `o.serveHttpCode()`, `o.serveJson()`, `o.serveRedirect()` or a basic `o.respond()`
	###
	o.serve()
	
###
This will build the templates then start the server, all depending on the config. 
###
lance.initialize().then ->
	# we're ready

###
Alternitavely...

There is a choice between `lance.initialize()`, which initializes everything in order, and manually initializing aspects of lance for more control.
###

lance.templater.initialize().then ->
	# The bundles have been compiled to:
	#	./projectDirectory/static/style.css
	#	./projectDirectory/static/app.js
	# from the ./projectDirectory/views directory.
	# and will be watched for changes (and any of their dependencies)
	# then recompiled automatically

	lance.start().then ->
		# we're ready
		
###
The new directory structure:
/project/
	/static/
		/my/
			/css/
				here.css
		app.js
		/images/
			image.png
	/views/
		index.jade
		style.styl
		app.coffee
		/images/
			image.png
	
	server.coffee (this)
###
```

### Templating explained

You can specify your own templater middleware. If none are specified, then Lance will default to checking whether `ect` is installed and will use that. 

```coffee

new Lance {
	templater:
		templater:
			ext: '.jade'
			engine: require 'jade'
			options: {} # Supplied to the engine on instantiation
}
```

### Optional modules

For these features to become avaliable, simply make sure they're installed.
- `browserify` for bundling coffee/js
	+ `coffee-react` for embedding JSX into Coffee
	+ `coffeeify` instead of cjsxify, without JSX
- `stylus` 
- `coffee-script`
- `uglify-js` for js compression
- `lactate` for static file serving

#### Stylus
Stylus is compulsary if you're going to bundle css assets; because Stylus can exist as pure css with the benefit of the `@require()` and `@import` bundling syntax. Any plain CSS file is concatenated, it is not resolved to an `@import`.

### Static assets
Lance handles these mostly automatically:
- CSS and Stylus
- CoffeeScript, CJSX and Javascript
- Static assets such as images, json, robots.txt etc.

On initialization:
- Bundles are rendered to the static directory
- Bundles are watched for changes, then rerendered
- Assets files are copied over to the static directory
- Assets files are watched for changes, then resaved
- Directories are watched for new directories and files

By default all static assets that match the regexp (found in the config's `templater.assets.match`) will be copied over to the static directory.
- For some filetypes, such as images, this means they can also be optimized. 
	+ TODO: Impliment asset stream hooking

```coffee
new Lance {
	templater:
		findIn: './views'
		saveTo: './static'
		
		###
		true by default, this causes `assets` to keep their directory structure inside the saveTo folder.
		###
		preserveDirectory: true
		
		bundle:
			# destination	: source
			"style.css"		: "style.styl"
			"app.js"		: "app.coffee"
}
```

The result is that the static directory will always have only what you want to make public, in one place, with a directory structure that will mirror your views.

## Tests
Cloned via the github repo, tests are manual in nature at the moment. Due to the complexity of a web server, they consist of scenarios for which must be manually tested and interacted with in the browser, currently.

All dependencies have unit tests.

```
       __                     
      / /___ _____  ________  
     / / __ `/ __ \/ ___/ _ \ 
    / / /_/ / / / / /__/  __/ 
   /_/\__/_/_/ /_/\___/\___/  
   
```