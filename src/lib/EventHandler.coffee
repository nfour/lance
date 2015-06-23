{ typeOf, merge, prettyError } = require '../utils'

module.exports = class EventHandler
	constructor: (@lance, @emitter) ->
		@emitter or= @lance
		@listen @emitter
		
	listen: (emitter) ->
		cfg = @lance.cfg.logging
		
		#
		# Logging
		#
		
		emitter.on 'err', (err, scope = '', reverse) ->
			console.error prettyError err, scope, reverse

		if cfg.requests
			emitter.on 'request', (o) ->
				timeDiff = new Date().getTime() - o.time.getTime()
				timeUnit = 'ms'

				if timeDiff > 1000
					timeDiff = timeDiff / 1000
					timeUnit = 's'

				console.log(
					( ' ' + timeDiff + timeUnit ).grey
					o.method.grey.bold
					( o.route.url.href ).toString().green
					require('util').inspect( o.path ).toString()[0..100].grey
					require('util').inspect( o.query ).toString()[0..100].grey
				)
				
		if cfg.startup
			emitter.on 'templater.ready', ->
				console.log '~ templater'.grey, 'ready'.green

			emitter.on 'server.starting', (lance) =>
				cfg = lance.cfg.server
				console.log '~ server'.grey, 'starting', 'on'.grey, ( if cfg.method is 'socket' then cfg.socket else cfg.host + ':' + cfg.port ).cyan

			emitter.on 'server.listening', ->
				console.log '~ server'.grey, 'listening'.green

			emitter.on 'server.ready', ->	console.log '~ server'.grey, 'ready'.green
			emitter.on 'ready', ->			console.log '~'.grey, 'ready'.green

		if cfg.debug
			debugAll = cfg.debug is true
			if debugAll or typeOf.Object cfg.debug
				if debugAll or cfg.debug?.watch
					emitter.on 'templater.watch', (fileDir) ->
						console.log 'templater.watch'.grey, fileDir

					emitter.on 'templater.watch.change', (fileDir, event) ->
						console.log 'templater.watch.change'.grey, fileDir

				if debugAll or cfg.debug?.render
					emitter.on 'templater.render.template', (fileDir) ->
						console.log 'templater.render.template'.grey, fileDir

					emitter.on 'templater.render.css', (fileDir) ->
						console.log 'templater.render.css'.grey, fileDir

					emitter.on 'templater.render.js', (fileDir) ->
						console.log 'templater.render.js'.grey, fileDir

					emitter.on 'templater.render.coffee', (fileDir) ->
						console.log 'templater.render.coffee'.grey, fileDir

					emitter.on 'templater.render.stylus', (fileDir) ->
						console.log 'templater.render.stylus'.grey, fileDir
						
					emitter.on 'templater.bundle.render', (fileDir) ->
						console.log 'templater.bundle.render'.grey, fileDir

				if debugAll or cfg.debug?.files
					emitter.on 'templater.writeFile', (to) ->
						console.log 'templater.writeFile'.grey, 'to'.grey, to

	###
		Relays all events from @emitter to the specified emitter.
	###
	relay: (emitter) ->
		emit = @emitter.emit.bind @emitter
		
		@emitter.emit = (args...) =>
			emitter.emit args...
			emit args...
	
	# [DEPRECATED]
	extend: (emittee) ->
		emittee._events = @emitter._events
		emittee.on		= @emitter.on.bind @emitter
		emittee.emit	= @emitter.emit.bind @emitter

		return emittee
