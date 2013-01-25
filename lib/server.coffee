
http		= require 'http'
parseUrl	= require('url').parse
parseQuery	= require('querystring').parse
Cookies		= require 'cookies'

lance = require './lance'

{clone, merge} = Object
{type} = Function

defaultRequestCb = (req, res) ->
	res.serve req, res, {
		code: 500 
		body: '<html><body>500</body></html>'
	}

lance.createServer = (requestCb) ->
	if requestCb and type( requestCb ) is 'function'
		lance.requestCb = requestCb
	else
		lance.requestCb = defaultRequestCb

	lance.session.server = http.createServer lance.requestHandler()

	return lance.session.server

lance.listen = ->
	return false if not lance.session.server
	
	return lance.session.server.listen.apply lance.session.server, arguments

lance.extendRequest = (req) ->
	href	= req.url
	url		= parseUrl req.url, true
	route	= lance.router.match url.pathname, req.method
	
	req.route		= route
	req.routes		= lance.router.namedRoutes
	req.path		= route.path
	req.splats		= route.splats
	req.callback	= lance.requestCb
	req.query		= parseQuery( url.query ) or {}
	
	return req
	
lance.extendResponse = (res) ->
	res.serve = @serve
	
	return res
	
lance.requestHandler = ->
	return (req, res) =>
		lance.extendRequest req
		lance.extendResponse res
		
		cookies = new Cookies req, res

		req.cookies =
		res.cookies = cookies

		lance.hooks.server.request.apply lance, [req, res]
		
		if req.route.callback
			req.route.callback.apply req, [req, res]
		else
			lance.requestCb.apply req, [req, res]

