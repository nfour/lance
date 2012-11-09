
{clone, merge} = Object

zlib	= require 'zlib'
path	= require 'path'

require './functions'
require './server'
require './hooks'
require './templating'

lanceExports	= require 'lance'
{lance}			= lanceExports

exports = {
	respond: (req, res, opt = {}) ->
		@hooks.server.respond.apply lanceExports, [req, res, opt]
		
		opt.encoding	= opt.encoding	or 'utf8'
		opt.code		= opt.code		or 500
		opt.headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
		opt.body		= opt.body		or ''
		
		setHeaders res, opt.headers # set headers, as we're not using res.writeHead()
		
		res.statusCode = opt.code
		
		finalize req, res, opt.body, (body) ->
			res.end body, opt.encoding
		
	serve: (req, res, opt = {}) ->
		@hooks.server.serve.apply lanceExports, [opt]

		if typeof opt is 'string' then opt = { view: opt }
			
		opt.code	= opt.code		or 200
		opt.headers	= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
		opt.body	= opt.body		or ''
		opt.data	= opt.data		or {}
		opt.view	= opt.view		or opt.template or '' # lets one choose the words template or view

		{templating} = lanceExports

		if templating.locals then merge opt.data, templating.locals

		if not opt.body and opt.view
			templating.render opt.view, opt.data, (err, rendered) =>
				if err
					lance.error 'Error', 'respond.serve -> templating.render', err
					rendered = ''

				opt.body = rendered

				@respond req, res, opt
		else
			console.log '>> Not using a templater'
			@respond req, res, opt
}

# calls the res.setHeader func for each header
setHeaders = (res, headers) ->
	for key, val of headers
		res.setHeader key, val
	
	return true

# handles compression, related headers and content-length
# takes a callback due to use of async zlib
finalize = (req, res, body, callback) ->
	normalize = (err, body) -> callback body
	
	acceptEncoding = req.headers['accept-encoding'] or ''
	
	if acceptEncoding.match /\bgzip\b/i
		res.setHeader 'content-encoding', 'gzip'
		zlib.gzip body, normalize
	else if acceptEncoding.match /\bdeflate\b/i
		res.setHeader 'content-encoding', 'deflate'
		zlib.deflate body, normalize
	else
		res.setHeader 'content-length', body.length
		callback body
	
	return true
	

publicExports = {
	serve: -> lance.serve.apply lance, arguments
}

# extend lance

merge lance, exports
merge lanceExports, publicExports

module.exports = exports

