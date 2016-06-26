Promise		= require 'bluebird'
Emitter		= require('events').EventEmitter
path		= require 'path'
cluster		= require 'cluster'
fs			= require 'fs'
os			= require 'os'
http		= require 'http'
require 'colors'

{ clone, merge, typeOf, format, coroutiner } = utils = require '../utils'

module.exports = coroutiner class Lance extends Emitter
	data	: data =
		cfg			: require '../config'
		mimetypes	: require '../data/mimetypes'
		
	cfg		: data.cfg
	utils	: utils
	
	EventHandler	: require './EventHandler'
	Templater		: require './Templater'
	Router			: require './Router'
	RequestHandler	: require './RequestHandler'

	constructor: (newCfg) ->
		@cfg = clone @cfg
		merge @cfg, newCfg if newCfg
		
		@eventHandler = new @EventHandler this
		
		# Captures errors ultimately uncaught through promises
		if handler = @cfg.catchUncaught or @cfg.catchUncaughtPromises
			handler = @onPossiblyUnhandledRejection if not typeOf.Function handler
			
			@cfg.Promise?.onPossiblyUnhandledRejection handler
			Promise.onPossiblyUnhandledRejection handler

		#
		# Config formatting
		#

		if @cfg.server.cluster is null
			@cfg.server.cluster = @cfg.server.workers > 1

		@paths =
			root: @cfg.root or path.dirname require.main.filename

		templater = @cfg.templater or @cfg.templating

		if templater.autoConstruct
			templater.root	= @paths.root if not templater.root
			@templater		= new @Templater templater, this
		
		if @cfg.server.static
			if typeOf.String @cfg.server.static
				@paths.static = @cfg.server.static
			else if @cfg.templater.saveTo
				@paths.static = @cfg.templater.saveTo
				
			if @paths.static and not path.isAbsolute @paths.static
				@paths.static = path.join @paths.root, @paths.static
		
		@router = new @Router @cfg.router, this
		
		try Lactate	= require 'lactate'
		
		if Lactate? and @cfg.server.static and @paths.static
			@staticServer = Lactate.dir @paths.static, {}
			console.log '~ server'.grey, 'serving static'.green

			@router.get ['/static/*', '/:file(favicon.ico|robots.txt)'], 'static', (o) =>
				@staticServer.serve ( o.path.file or o.splats.join '.' ), o.req, o.res

		if @cfg.routes?.length
			@router.route route for route in @cfg.routes
		
		@cfg.compress = clone require('../config').server.compress
		
		if typeOf.Object @cfg.server.compress
			@cfg.compress = @cfg.server.compress
	
	initialize: ->
		@templater.initialize().then =>
			@start().then()
		
	onPossiblyUnhandledRejection: (err) =>
		@emit 'err', err, 'Promise.onPossiblyUnhandledRejection'

	createServer: (requestCallback) ->
		@requestCallback = requestCallback or ->

		http.globalAgent.maxSockets = @cfg.server.maxSockets or 20
		
		@server = new http.Server (req, res) =>
			new @RequestHandler( req, res, this ).parse()

		@emit 'server.starting', this

		@server.on 'listening', =>
			if @cfg.server.method is 'socket' and @cfg.server.socketPerms
				fs.chmod @cfg.server.socket, @cfg.server.socketPerms

			if not cluster.isWorker or cluster.worker.id is 1
				@emit 'server.listening', this

		return @server

	createCluster: ->
		@cfg.server.method = 'port' if @cfg.server.method is 'socket' and not @cfg.server.socket

		if cluster.isWorker
			server = @createServer @requestCallback

			yield @listen()
		else
			workerLimit = os.cpus().length
			workerLimit = @cfg.server.workers if @cfg.server.workers < workerLimit

			# clean out old sockets
			if @cfg.server.method is 'socket'
				if fs.existsSync @cfg.server.socket
					fs.unlinkSync @cfg.server.socket

			@emit 'cluster.starting', this

			cluster.on 'online', (args...) => @emit 'cluster.worker.online', args...
			cluster.on 'offline', (args...) => @emit 'cluster.worker.exit', args...

			c = 0
			while c < workerLimit
				cluster.fork()
				++c

			yield return

	listen: -> new Promise (resolve, reject) =>
		if @cfg.server.method is 'socket'
			@server.listen @cfg.server.socket, resolve
		else
			@server.listen @cfg.server.port, @cfg.server.host, resolve

	start: ->
		if @cfg.server.cluster
			return @createCluster()
		else
			@createServer()

			return @listen()

	merge this, @prototype, 1