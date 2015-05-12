Lance = require '../../lib/Lance'

lance = new Lance {
	server:
		port: 1337
		static	: './static'
		
	root	: __dirname
	
	routes: [
		[ "all", "*", (o) ->
			o.serve { view: 'index' }
		]
	]
	
	templater:
		findIn	: './views'
		saveTo	: './static'
		
		locals:
			test2: 2
		
		debug:
			files: true
			render: true
			
		bundle:
			"style.css"	: "style.styl"
			"app.js"	: "client.coffee"
		
		#templater:
		#	ext		: '.jade'
		#	engine	: require 'jade'
		
		templater:
			options:
				cache	: true
				watch	: true
				open	: '<<'
				close	: '>>'

}

lance.on 'request.unparsed', -> console.log 'req'

lance.initialize()


