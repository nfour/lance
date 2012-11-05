
http		= require 'http'
parseUrl	= require('url').parse
parseQuery	= require('querystring').parse

require './functions'
require './hooks'
require './router'

{clone, merge} = Object

lanceExports	= require 'lance'
{lance}			= lanceExports

defaultRequestCb = (req, res) ->
	res.serve req, res, {
		code: 500 
		body: '<html><body>500</body></html>'
	}

exports = {
	createServer: (@requestCb = defaultRequestCb) ->
		@session.server = http.createServer( @requestHandler @requestCb )

		return @session.server

	listen: () ->
		return false if ! @session.server
		
		return @session.server.listen.apply @session.server, arguments
		
	extendRequest: (req) ->
		href	= req.url
		url		= parseUrl req.url, true
		route	= @router.match url.pathname
		
		req.route		= route
		req.routes		= @router.namedRoutes
		req.path		= route.path
		req.splats		= route.splats
		req.callback	= @requestCb
		req.query		= parseQuery( url.query ) or {}
		req.url			= url
		req.href		= href
		
		return req
		
	extendResponse: (res) ->
		res.serve = lanceExports.serve
		
		return res
		
	requestHandler: (requestCb) ->
		return (req, res) =>
			@extendRequest req
			@extendResponse res
			
			@hooks.server.request.apply lanceExports, [req, res]
			
			if req.route.callback
				req.route.callback.apply req, [req, res]
			else
				requestCb.apply req, [req, res]
}

publicExports = {
	createServer	: -> lance.createServer.apply	lance, arguments
	listen			: -> lance.listen.apply			lance, arguments
}

# extend lance

merge lance, exports
merge lanceExports, publicExports

module.exports = exports

