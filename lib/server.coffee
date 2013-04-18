
path		= require 'path'
http		= require 'http'
parseUrl	= require('url').parse
parseQuery	= require('querystring').parse
Cookies		= require 'cookies'
lance		= require './lance'
zlib		= require 'zlib'

{clone, merge, typeOf} = lance.utils

lance.httpCodes = require './httpcodes'

lance.createServer = (requestCallback) ->
	if requestCallback and typeOf( requestCallback ) is 'function'
		lance.requestCallback = requestCallback
	else
		lance.requestCallback = (req, res) -> res.serve.code 404

	lance.server = http.createServer lance.requestHandler()

	return lance.server

lance.listen = ->
	return lance.server.listen.apply lance.server, arguments

lance.extendRequest = (req, done = ->) ->
	url		= parseUrl req.url, true
	route	= lance.router.match url.pathname, req.method

	req.route		= route
	req.routes		= lance.router.namedRoutes
	req.callback	= lance.requestCb

	req.path	= route.path
	req.splats	= route.splats
	
	req.GET		= url.query
	req.POST	= {}

	if req.method is 'POST'
		postBody = ''

		req.on 'data', (chunk) ->
			postBody += chunk

		req.on 'end', ->
			req.POST = parseQuery postBody

			done()
	else
		done()
	
lance.extendResponse = (res) ->
	res.respond = (opt = {}) ->
		{req} = res

		opt.code		= opt.code		or 200
		opt.headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
		opt.encoding	= opt.encoding	or 'utf8'
		opt.body		= opt.body		or ''

		for key, val of opt.headers
			res.setHeader key, val

		res.statusCode = opt.code

		if lance.cfg.compress and req.headers['accept-encoding']
			res.compress opt.body, (err, body) ->
				res.end body, opt.encoding
		else
			opt.headers['content-length'] = opt.body.length or 0
			res.end opt.body, opt.encoding

	res.serve = (opt = {}) ->
		if typeof opt is 'string'
			opt = { view: opt }
			
		opt.code		= opt.code		or 200
		opt.headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
		opt.body		= opt.body		or ''
		opt.encoding	= opt.encoding	or 'utf8'
		opt.data		= opt.data		or {}
		opt.view		= opt.view		or opt.template or '' # lets one choose the words template or view

		if lance.templating.locals
			opt.data = merge clone(lance.templating.locals), opt.data

		if not opt.body and opt.view
			lance.templating.render opt.view, opt.data, (err, rendered) =>
				if err
					return res.serve.code 400

				opt.body = rendered

				res.respond opt
		else
			res.respond opt

	res.serve.json = (obj) ->
		res.writeHead 200, { 'content-type': 'application/json' }
		res.end JSON.stringify obj

	res.serve.redirect = (path = '') ->
		res.writeHead 302, { 'location': path, 'content-type': 'text/plain; charset=utf-8' }
		res.end()

	res.serve.code = (code, headers = { 'content-type': 'text/plain; charset=utf-8' }, body = '') ->
		res.writeHead code, headers

		if body
			res.end body
		else
			title = lance.httpCodes[ code.toString() ] or ''
			res.end "#{code} #{title}"

	res.compress = (body, done = ->) ->
		{req} = res

		handler = (err, body) ->
			if err
				return done lance.error(
					type: 'warning'
					scope: 'lance.compress'
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

	return res

lance.requestHandler = ->
	return (req, res) ->
		req.cookies =
		res.cookies = new Cookies req, res, lance.requestHandler.keygrip or false

		req.res = res
		res.req = req
		
		lance.extendResponse res
		lance.extendRequest req, ->
			if req.route.callback
				req.route.callback req, res
			else
				lance.requestCallback req, res

lance.compress = (res, body, done) -> res.compress body, done


