Lance	= require '../../lib/Lance'
Promise	= require 'bluebird'
config	= require './config'

{ merge } = require 'lutils'

lance = new Lance merge config, {
	
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
		templater:
			ext		: '.jade'
			engine	: require 'jade'
			options	: null
}

	
lance.on 'request.unparsed', -> console.log 'req'

lance.initialize()

