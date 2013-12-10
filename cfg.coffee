
module.exports = {
	ascii			: false # displays ascii art for lance at startup
	catchUncaught	: true # catches any uncaught errors into lance.error()
	compress		: false
	keygripKeys: ['Wwavifkuiv7C5JFNCDTiyD6U1RGxz48f'] # used for encoding cookies
	
	router	: {
		cache: true
	}

	server: {
		cluster		: null # null, true, false
		workers		: 99 # if 1 or less, will not use the cluster unless cluster is set to true
		port		: 80
		host		: '127.0.0.1'
		socket		: ''
		socketPerms	: 0o0666
		method		: 'port'
		requestCb	: false
		maxSockets	: 20
	}

	rootDir: ''
	
	tpl: {
		rootDir	: ''

		locals: {}
		watchChangeWait: 1500 # Waits this long after each change event before saving
		watchInterval: 2000 # After each change event, wait this long before acknowledging any more for this file
		ect: {
			engine	: undefined
			ext		: '.ect'
			findIn	: ''
			minify	: true

			options: { # options object that is passed when initiating an ECT engine
				root	: ''
				cache	: true
				ext		: ''
				watch	: true
				open	: '<?'
				close	: '?>'
			}
		}

		stylus: {
			ext			: '.styl'
			engine		: undefined
			renderTo	: 'static'
			findIn		: ''
			options		: {}
			minify		: true
			watch		: true
			inherit		: true
		}
		
		coffee: {
			ext			: '.coffee'
			engine		: undefined
			renderTo	: 'static'
			findIn		: ''
			options		: {}
			minify		: true
			watch		: true
			inherit		: true
		}

		css: {
			minify			: true
			ext				: '.css'
			renderTo		: ''
			findIn			: ''
			watch			: true
			inherit			: true 
		}

		js: {
			minify			: true
			ext				: '.js'
			renderTo		: ''
			findIn			: ''
			watch			: true
			inherit			: true
		}
	}

}