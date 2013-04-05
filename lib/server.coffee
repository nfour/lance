
http		= require 'http'
parseUrl	= require('url').parse
parseQuery	= require('querystring').parse
Cookies		= require 'cookies'
lance		= require './lance'

{clone, merge} = Object
{type} = Function

lance.createServer = (requestCallback) ->
	if requestCallback and type( requestCallback ) is 'function'
		lance.requestCallback = requestCallback
	else
		lance.requestCallback = ->
			lance.serve.code 404

	lance.session.server = http.createServer lance.requestHandler()

	return lance.session.server

lance.listen = ->
	if lance.session.server
		return lance.session.server.listen.apply lance.session.server, arguments

lance.extendRequest = (req, done = ->) ->
	lance.req = req

	href	= req.url
	url		= parseUrl href, true
	route	= lance.router.match url.pathname, req.method

	req.route		= route
	req.routes		= lance.router.namedRoutes
	req.path		= route.path
	req.splats		= route.splats
	req.callback	= lance.requestCb
	req.href		= href

	req.query	=
	req.GET		= url.query

	req.POST	= {}

	if req.method is 'POST'
		postBody = ''

		req.on 'data', (chunk) ->
			postBody += chunk

		req.on 'end', ->
			console.log postBody
			req.POST = parseQuery postBody

			done()
	else
		done()
	
lance.extendResponse = (res) ->
	lance.res	= res
	res.serve	= lance.serve

	return res

lance.requestHandler = ->
	return (req, res) =>
		cookies = new Cookies req, res, lance.keygrip

		req.cookies =
		res.cookies = cookies
		
		lance.extendResponse res
		lance.extendRequest req, ->
			if req.route.callback
				req.route.callback req, res
			else
				lance.requestCallback req, res

