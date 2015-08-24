Lance	= require '../../lib/Lance'
fs		= require 'fs'
config	= require './config'

{ merge } = require 'lutils'

lance = new Lance merge config, {
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


}


lance.on 'request.unparsed', -> console.log 'req'

lance.initialize()

