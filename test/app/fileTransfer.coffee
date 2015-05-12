Lance	= require '../../lib/Lance'
fs		= require 'fs'

lance = new Lance {
	server:
		port: 1337
		static	: './static'
		
	root	: __dirname
	
	routes: [
		[ "all", "*", (o) ->
			data = {}
			
			# TODO: test PUT, DELETE etc. and look them up for what they CAN take in legally
			
			if o.files.fileHere
				data.file = fs.readFileSync o.files.fileHere.file, 'utf8'
				console.log 'FILE'.grey, o.files.fileHere.file, 'CONTENT'.grey, data.file?[0..200]
				o.files.fileHere.delete().then ->
					console.log 'deleted file!'
				
			o.serve { view: 'fileTransfer', data }
		]
	]
	
	templater:
		findIn	: './views'
		saveTo	: './static'
		
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

