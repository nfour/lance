
{clone, merge} = Object

zlib	= require 'zlib'
path	= require 'path'

require './functions'
require './server'
require './hooks'
require './templating'

lanceExports	= require 'lance'
{lance}			= lanceExports

# calls the res.setHeader func for each header
setHeaders = (res, headers, body) ->
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
	
exports = {
	respond: (req, res, opt = {}) ->
		@hooks.server.respond.apply lanceExports, [req, res, opt]
		
		code		= opt.code		or 500
		headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
		body		= opt.body		or ''
		encoding	= opt.encoding	or 'utf8'
		
		setHeaders res, headers # set headers, as we're not using writeHead()
		
		res.statusCode = code
		
		finalize req, res, body, (body) ->
			res.end body, encoding
			
	serve: (req, res, opt = {}) ->
		@hooks.server.serve.apply lanceExports, [opt]
		
		opt = { view: opt } if typeof opt is 'string'
			
		defaultOpt = {
			view	: ''
			template: ''
			headers	: { 'content-type': 'text/html; charset=utf-8' }
			code	: 200
			data	: {}
			body	: ''
		}
		
		opt = merge defaultOpt, opt
		
		opt.view = opt.view or opt.template # lets one choose the words template or view

		opt.data.cache = true

		if not opt.body and opt.view
			lanceExports.templating.render opt.view, opt.data, (err, rendered) =>
				if err
					console.error lance.error 'Error', 'templating renderEct', err
					rendered = ''

				opt.body = rendered

				@respond req, res, opt
		else
			console.log '>> Not using a templater'
			@respond req, res, opt
}

publicExports = {
	serve: -> lance.serve.apply lance, arguments
}

# extend lance

merge lance, exports
merge lanceExports, publicExports

module.exports = exports

