Lance		= require '../../lib/Lance'
Promise		= require 'bluebird'
config		= require './config'
showUsage	= require './handlers/debugging'

{ merge } = require 'lutils'

lance = new Lance merge config, {
	routes: [
		[ "get", "/", (o) ->
			o.serve { view: 'index' }
		]
	]
	
	templater:
		templater:
			ext		: '.jade'
			engine	: require 'jade'
			options	: null
	
		watch: true
		
		stylus	: disabled	: true
		#css		: disabled	: true
		coffee	: disabled	: false
		assets	: disabled	: true
		
		debugging:
			fileWriting: false

}

startTime = new Date()
lance.initialize().then ->
	showUsage ->
		Promise.all( for i in [0..10]
			lance.templater.bundle lance.cfg.templater.bundle
		).then ->
			console.log lance.templater.cfg
			console.log 'Done,', (new Date() - startTime) / 1000, 'seconds'
			showUsage ->
				setTimeout showUsage, 5000

	
###
	Greenlisted:
		- File watching
		- File writing/streaming
		- Assets

###
