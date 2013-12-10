
path		= require 'path'
cluster		= require 'cluster'
os			= require 'os'
fs			= require 'fs'
http		= require 'http'
parseUrl	= require('url').parse
querystring	= require('querystring')
Cookies		= require 'cookies'
L			= require './lance'
zlib		= require 'zlib'
colors		= require 'colors'

{clone, merge, typeOf} = L.utils

L.httpCodes = require './httpcodes'

L.createServer = (requestCallback) ->
	if requestCallback and typeOf.Function requestCallback
		L.requestCallback = requestCallback
	else
		L.requestCallback = (req, res) -> res.serve.code 404

	http.globalAgent.maxSockets = L.cfg.server.maxSockets or 20
	
	L.server = http.createServer L.requestHandler()

	if not cluster.isWorker
		console.log 'Initiating:'.grey, 'Non-Cluster server'
	
	serverEvents L.server

	return L.server

L.listen = (listener) ->
	return L.server.listen.apply L.server, arguments

L.createCluster = (done = ->) ->
	cfg = L.cfg.server

	cfg.method = 'port' if cfg.method is 'socket' and not cfg.socket

	if cluster.isWorker
		server = L.createServer cfg.requestCb

		if cfg.method is 'socket'
			L.listen cfg.socket, done
		else
			L.listen cfg.port, cfg.host, done

	else
		workerLimit = os.cpus().length
		workerLimit = cfg.workers if cfg.workers < workerLimit

		cleanSocket()

		console.log 'Initiating:'.grey, 'Cluster with [', workerLimit.toString().cyan, '] workers'

		clusterEvents cluster

		c = 0
		while c < workerLimit
			cluster.fork()
			++c

		done()

L.start = (done = ->) ->
	cfg = L.cfg.server

	if cfg.cluster
		L.createCluster done
	else
		L.createServer()

		if cfg.method is 'socket'
			L.listen cfg.socket, done
		else
			L.listen cfg.port, cfg.host, done

cleanSocket = (socket) ->
	cfg = L.cfg.server
	
	socket or socket = cfg.socket

	return false if cfg.method isnt 'socket'

	if fs.existsSync socket
		fs.unlinkSync socket

		return true

serverEvents = (server) ->
	cfg = L.cfg.server

	server.on 'listening', ->
		L.emit 'listening'

		if cfg.method is 'socket' and cfg.socketPerms
			fs.chmod cfg.socket, cfg.socketPerms

		if not cluster.isWorker or cluster.worker.id is 1
			str = if cfg.method is 'socket' then cfg.socket else cfg.host + ':' + cfg.port
			console.log 'Listening on:'.grey, str.cyan

clusterEvents = (cluster) ->
	cluster.on 'online', (worker) =>
		workerEvents worker
		console.log 'Worker [', worker.id.toString().cyan, ']', 'online'.green

	cluster.on 'exit', (worker, code, signal) =>
		console.log 'Worker [', worker.id.toString().cyan, ']', 'offline'.red

workerEvents = (worker) ->

#
# Extension of req and res
#

extend = {}
extend.render = (view = '', data = {}, done = ->) ->
	res = this

	if L.tpl.locals
		data = merge clone( L.tpl.locals ), data

	data.GET	= res.req.GET
	data.POST	= res.req.POST
	data.req	= res.req

	L.tpl.render view, data, done

extend.serve = (opt = {}) ->
	res = this

	if typeof opt is 'string'
		opt = {
			view: arguments[0]
			data: arguments[1]
		}

	opt.code		or opt.code			= 200
	opt.headers		or opt.headers		= { 'content-type': 'text/html; charset=utf-8' }
	opt.body		or opt.body			= ''
	opt.encoding	or opt.encoding		='utf8'
	opt.data		or opt.data			= {}
	opt.view		or opt.view			= ''

	opt.data.GET	= res.req.GET
	opt.data.POST	= res.req.POST
	opt.data.req	= res.req

	if L.tpl.locals
		opt.data = merge clone( L.tpl.locals ), opt.data

	render = opt.instance or L.tpl.render

	L.emit 'serve', opt

	if opt.view
		render opt.view, opt.data, (err, rendered) =>
			if err
				return res.serve.code 500

			opt.body = rendered

			res.respond opt
	else
		res.respond opt

extend.serve.json = (obj) ->
	res = this
	# TODO: make these use .respond()

	L.emit 'serve.json', arguments

	res.writeHead 200, { 'content-type': 'application/json' }
	res.end JSON.stringify obj

extend.serve.redirect = (path = '', query = {}) ->
	res = this

	L.emit 'serve.redirect', arguments

	if Object.keys( query ).length
		path += '?' + querystring.stringify( query )

	res.writeHead 302, { 'location': path }
	res.end()

extend.serve.code = (code, headers = { 'content-type': 'text/plain; charset=utf-8' }, body = '') ->
	res = this

	L.emit 'serve.code', arguments

	res.writeHead code, headers

	if body
		res.end body
	else
		title = L.httpCodes[ code.toString() ] or ''
		res.end "#{code} #{title}"

extend.respond = (opt = {}) ->
	res = this
	{req} = res

	opt.code		= opt.code		or 200
	opt.headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
	opt.encoding	= opt.encoding	or 'utf8'
	opt.body		= opt.body		or ''

	L.emit 'respond', opt

	for key, val of opt.headers
		res.setHeader key, val

	res.statusCode = opt.code

	if L.cfg.compress and req.headers['accept-encoding']
		res.compress opt.body, (err, body) ->
			res.end body, opt.encoding
	else
		res.setHeader 'content-length', opt.body.length or 0
		res.end opt.body, opt.encoding

extend.compress = (body, done = ->) ->
	res = this
	{req} = res

	handler = (err, body) ->
		if err
			return done L.error(
				type: 'warning'
				scope: 'L.compress'
				error: err
			), body

		done null, body

	acceptEncoding = req.headers['accept-encoding'] or ''

	if acceptEncoding.match /\bgzip\b/i
		res.setHeader 'content-encoding', 'gzip'
		zlib.gzip body, handler
	else if acceptEncoding.match /\bdeflate\b/i
		res.setHeader 'content-encoding', 'deflate'
		zlib.deflate body, handler
	else
		res.setHeader 'content-length', body.length or 0
		done null, body

extend.next = ->
	req = this
	{res} = req

	url = req.route.url

	newRoute		= L.router.match url.pathname, req.method, req.route.index + 1
	newRoute.url	= url

	req.route		= newRoute
	req.path		= newRoute.path
	req.splats		= newRoute.splats

	L.extendResponse res

	if newRoute.callback
		newRoute.callback req, res

L.extendRequest = (req, done = ->) ->
	url			= parseUrl req.url, true
	route		= L.router.match url.pathname, req.method
	route.url	= url

	req.route		= route
	req.routes		= L.router.namedRoutes
	req.callback	= L.requestCb
	req.path		= route.path
	req.splats		= route.splats

	req.next = extend.next.bind req

	req.GET		= url.query
	req.POST	= {}

	if req.method is 'POST'
		postBody = ''

		req.on 'data', (chunk) ->
			postBody += chunk

		req.on 'end', ->
			req.POST = querystring.parse postBody

			done()
	else
		done()

L.extendResponse = (res) ->
	res.render			= extend.render.bind res
	res.serve			= extend.serve.bind res
	res.next			= extend.next.bind res.req
	res.serve.json		= extend.serve.json.bind res
	res.serve.redirect	= extend.serve.redirect.bind res
	res.serve.code		= extend.serve.code.bind res
	res.respond			= extend.respond.bind res
	res.compress		= extend.compress.bind res

	return res

L.requestHandler = ->
	return (req, res) ->
		req.cookies =
		res.cookies = new Cookies req, res, L.requestHandler.keygrip or false

		req.res = res
		res.req = req
		
		L.extendResponse res
		L.extendRequest req, ->
			L.emit 'request', res, req

			if req.route.callback
				req.route.callback req, res
			else
				L.requestCallback req, res

L.compress = (res, body, done) -> res.compress body, done


