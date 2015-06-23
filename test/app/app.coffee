Lance = require '../../lib/Lance'
Promise = require 'bluebird'

lance = new Lance {
	server:
		port: 1337
		static	: './static'
		
	root	: __dirname
	
	routes: [
		[ "get", "/badTemplate", Promise.coroutine (o) ->
			o.serve { view: 'indexaaaaaa' }
			yield return
		]
		[ "get", "/", (o) ->
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

lance.router.get '/badTemplate2', Promise.coroutine (o) ->
	o.serve { view: 'not real' }
	yield return