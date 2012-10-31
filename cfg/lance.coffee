
module.exports = {
	lactate:
		cache: true

	templating: {
		root	: ''

		template: {
			ext		: '.~~~'
			engine	: undefined
			options	: {}
		}

		ect: {
			engine	: false
			ext		: '.ect'
			findIn	: ''

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
		}
		
		coffee: {
			ext		: '.coffee'
			engine	: undefined
			renderTo: 'static'
			findIn	: ''
			options	: {}
		}
	}

}