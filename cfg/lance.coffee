
module.exports = {
	ascii: true # displays ascii art for lance at startup
	catchUncaughtErrors: true # catches any uncaught errors into lance.error()

	keygripKeys: ['Wwavifkuiv7C5JFNCDTiyD6U1RGxz48f'] # used for encoding cookies

	templating: {
		root	: ''

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
			ext		: '.styl'
			engine	: undefined
			renderTo: 'static'
			findIn	: ''
			options	: {}
			minify	: true
		}
		
		coffee: {
			ext		: '.coffee'
			engine	: undefined
			renderTo: 'static'
			findIn	: ''
			options	: {}
			minify	: true
		}
	}

}