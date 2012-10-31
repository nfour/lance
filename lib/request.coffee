
http		= require 'http'
parseUrl	= require('url').parse

require './functions'

lanceExports	= require 'lance'
lance			= lanceExports.lance

cfg = {
	userAgent: 'I request some pie'
}

exports = {
	get: (href, callback) ->
		return false if ! href
		
		url		= parseUrl href
		data	= ''
		opt	= {
			method	: 'GET'
			host	: url.host
			path	: url.path
		}
		
		req = http.request opt, (res) ->
			res.setEncoding 'utf8'
			
			console.log '>> request.get: ', url

			res.on 'data', (chunk) ->
				data += chunk

			res.on 'end', () ->
				req.end()
				callback null, data
				

		req.on 'error', (err) ->
			console.log '>> Error, request.get: ', url, err.message
			req.end()
			callback err, data
		
	post	: () ->
	options	: () ->
	head	: () ->
	put		: () ->
	delete	: () ->
	trace	: () ->
	connect	: () ->
}

publicExports = {
	get		: -> lance.request.get.apply lance.request, arguments
	GET		: -> lance.request.get.apply lance.request, arguments
	post	: -> lance.request.post.apply lance.request, arguments
	POST	: -> lance.request.post.apply lance.request, arguments
}

# extend lance

lance.request			= exports
lanceExports.request	= publicExports

module.exports = exports