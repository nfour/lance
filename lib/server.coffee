
http		= require 'http'
parseUrl	= require('url').parse
parseQuery	= require('querystring').parse
Cookies		= require 'cookies'
lance		= require './lance'

{clone, merge} = Object
{type} = Function

key		= 'Wwavifkuiv7C5JFNCDTiyD6U1RGxz48f' # put this in the cfg - may want to save to file on first run
keygrip	= require('keygrip')([key])

lance.createServer = (requestCallback) ->
	if requestCallback and type( requestCallback ) is 'function'
		lance.requestCallback = requestCallback
	else
		lance.requestCallback = (req, res) ->
			res.serve.code '500'

	lance.session.server = http.createServer lance.requestHandler()

	return lance.session.server

lance.listen = ->
	if not lance.session.server
		return lance.error 'err', "lance.listen, No server"
	
	return lance.session.server.listen.apply lance.session.server, arguments

lance.extendRequest = (req, done = ->) ->
	href	= req.url
	url		= parseUrl href, true
	route	= lance.router.match url.pathname, req.method

	req.route		= route
	req.routes		= lance.router.namedRoutes
	req.path		= route.path
	req.splats		= route.splats
	req.callback	= lance.requestCb

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
	res.serve = @serve

	return res

lance.requestHandler = ->
	return (req, res) =>
		cookies = new Cookies req, res, keygrip

		req.cookies =
		res.cookies = cookies
		
		lance.extendResponse res
		lance.extendRequest req, ->
			if req.route.callback
				req.route.callback req, res
			else
				lance.requestCallback req, res

