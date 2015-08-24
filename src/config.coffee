
module.exports =
	###
		Your project root directory (Optional)
		@property {String}
		@default `path.dirname require.main.filename`
	###
	root: ''

	###
		Determines logging to stdout/stderr on certain events.
	###
	logging:
		startup		: true
		requests	: true
		errors		: true
		
		###
			true	:  Minimal debug information is output to stdout.
			Object	:
				files	: true
				render	: true
				watch	: true
			false	: No debug information is output
		###
		debug: false

	catchUncaught: true

	###
		HTTP server construction, with support for clustered servers.
	###
	server:
		cluster		: null # null, true, false
		workers		: 1 # if 1 or less will not use the cluster unless cluster is set to true
		port		: 80
		host		: '0.0.0.0'
		method		: 'port'
		socket		: ''
		socketPerms	: 0o0666
		maxSockets	: 20
				
		###
			Whether static file requests will be intercepted and served by `lactate`.
			If this cannot resolve a static directory it will not serve static files.
			
			true	: ENABLED	uses templater's saveTo path
			String	: ENABLED	a relative path to `lance.root` or an absolute path
			false	: DISABLED
		###
		static: true
		
		###
			Whether to utilize gzip/deflate compression in responses
			
			true	: ENABLED	with defaults as below
			false	: DISABLED
			Object	: ENABLED	specify your own options to the createGzip and createDeflate zlib classes
				{ createGzip: {}, createDeflate: {} }
		###
		compress:
			createGzip		: { level: 1 }
			createDeflate	: null

		###
			Busboy options for parsing form data, see: https://github.com/mscdex/busboy
		###
		busboy:
			limits:
				fileSize: 4 * 1024 * 1024 # bytes
				
		###
			Time before temp files (such as file uploads) will persist on the filesystem
			before being deleted.
		###
		tempTimeout: 60000

	
	###
		routes: [
			[ 'GET', '/:pattern/here', '?name?', (o) ->
				o.next()
			]
		]
		
	###

	###
		The templater governs a `findIn` directory.
		The goal is to populate the `saveTo` folder with assets and
		to serve markup from a templating language -- automatically.
	###
	templater:
		###
			Any default local variables that will be avaliable
			to a templater. These are merged in with request-specific locals.
		###
		locals: {}
		
		###
			Browserify and Stylus bundling/rendering.
			Destination is a relative path to the `saveTo` directory.
			Source is a relative path from the `findIn` directory.
			
			The source may be any of the engines below (besides the templater).
			
			Example:
				"destination.css"	: "source.styl"
				"destination.js"	: "source.coffee"
		###
		bundle: {}
		
		browserify:
			extensions	: [ '.js', '.coffee', '.cjsx' ]
			debug		: false # Source maps
			
			###
				Allows transforms to be specified as an array of arrays of arguements to the Browserify().transform function
				eg. transform: [ [ require('coffeeify'), { global: true } ] ]
			###
			transform	: null

		###
			Fallback paths for the below engines
		###
		saveTo: null
		findIn: null
		
		#
		#	ENGINES
		#
		
		
		###
			The templating engine for rendering markup.
			Defaults to ECT.js if no engine exists and `ect` is installed.
		###
		templater:
			engine	: undefined
			ext		: ''
			findIn	: null
			minify	: false

			# If ECT.js be fallen back to, use these as the options when constructing the engine.
			ect: 
				root	: ''
				ext		: ''
				cache	: true
				watch	: true
				open	: '<?'
				close	: '?>'
			
		stylus:
			disabled: false
			ext		: '.styl'
			engine	: null
			saveTo	: null
			findIn	: null
			minify	: false
			inherit	: true # Inherits unset options from `css`
			options	:
				'include css': true # Allows `@import 'some.css'` to concat
				cache: false # Workaround for imports
		
		coffee:
			disabled: false
			ext		: '.coffee'
			engine	: null
			saveTo	: null
			findIn	: null
			minify	: false
			inherit	: true # Inherits unset options from `js`
			options	: {}
			
		css:
			disabled: false
			ext		: '.css'
			saveTo	: null
			findIn	: null
			minify	: false
			inherit	: true # Inherits unset options from `stylus`

		js:
			disabled: false
			ext		: '.js'
			saveTo	: null
			findIn	: null
			minify	: false
			inherit	: true # Inherits unset options from `coffee`

		# Copy over any whitelisted file to the saveTo directory
		assets:
			disabled: false
			saveTo	: null
			findIn	: null
			
			###
				All files in the templater's directory are matched against this regex.
				If there is a match, it is an asset.
			###
			match	: /// \.(
				png|jpg|gif|ico
			|	woff|eot|ttf|svg|pdf
			)$ ///i

			###
				Any folder/file with this prefix is ignored
			###
			ignorePrefix: ''
		
		#
		#	ADVANCED OPTIONS
		#
		
		###
			Whether Stylus/Css/Js/CoffeeScript files and their bundled
			dependencies are watche for changes to proc a recompile
		###
		watch: true
		
		###
			A debugger, for toggling functionality to diagnose issues
		###
		debugging:
			fileWriting: true
		
		###
			Causes asset files to maintain their directory structure on render.
			
			Assuming /findInDirectory/path/of/img.jpg we then save it accordingly:
				true	: /saveToDirectory/path/of/img.jpg
				false	: /saveToDirectory/img.jpg
		###
		preserveDirectory: true

		###
			Time between each watch `change` event on a particular file before the file is re-rendered
		###
		watchTimeout: 1500
		###
			 Used to prevent frequent file re-writing
		###
		writeTimeout: 250
		
		###
			true	: Enabled, initialized in the background
			false	: Disabled, templater.initialize() must be called manually
		###
		autoInitialize	: false
		
		###
			Whether a Templater instance is added on construction.
			true	: lance.templater exists
			false	: lance.templater is undefined
		###
		autoConstruct	: true
	
	router:
		cache: false