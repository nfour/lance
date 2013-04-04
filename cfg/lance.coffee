
module.exports = {
	ascii: true
	lactate:
		cache: true

	templating: {
		root	: ''

		template: {
			ext		: '.~~~'
			findIn	: ''
			engine	: undefined
			options	: {}
			minify	: true
		}

		toffee: {
			engine	: undefined
			ext		: '.toffee'
			findIn	: ''
			minify	: true

			options: {}
		}

		ect: {
			engine	: undefined
			ext		: '.ect'
			findIn	: ''
			minify	: true

			options: {
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