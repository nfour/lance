Promise		= require 'bluebird'
Browserify	= require 'browserify'
config		= require './config'
require 'colors'
showUsage	= require './handlers/debugging'

setInterval ->
	1
, 100


render = ->
	new Promise (resolve, reject) ->
		b = Browserify [ __dirname + "/views/_js/app.coffee" ], {
			extensions: [ '.js', '.coffee', '.cjsx' ]
			transform: [ 'coffeeify' ]
		}
		
		b.on 'file', (fileDir) ->
			
		readStream = b.bundle().on 'error', (err) ->
			readStream.end?()
			console.log 'err', err
			reject()
		
		readStream.on 'data', ->
		
		readStream.on 'end', ->
			readStream = b = null
			resolve()

		

startTime = new Date()

do batchRender = ->
	showUsage ->
		render().then ->
			console.log 'Finished,', new Date() - startTime, 'ms'
			
			showUsage ->
				setTimeout showUsage, 5000
			
			batchRender()


###
	Conclusions:
		browserify will bloat memory no matter what! :|

###

