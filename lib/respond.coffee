
lance = require './lance'

zlib	= require 'zlib'
path	= require 'path'

{clone, merge} = Object

lance.httpCodes = require './httpcodes'

lance.serve	= (req, res, opt = {}) ->
	if typeof opt is 'string'
		opt = { view: opt }
		
	opt.code	= opt.code		or 200
	opt.headers	= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
	opt.body	= opt.body		or ''
	opt.data	= opt.data		or {}
	opt.view	= opt.view		or opt.template or '' # lets one choose the words template or view

	if lance.templating.locals
		merge opt.data, lance.templating.locals

	opt.data.req ?= req
	opt.data.res ?= res

	if not opt.body and opt.view
		lance.templating.render opt.view, opt.data, (err, rendered) =>
			if err
				return lance.serve.code 400

			opt.body = rendered

			lance.respond req, res, opt
	else
		lance.respond req, res, opt

lance.serve.json = (obj) ->
	lance.res.writeHead 200, { 'content-type': 'application/json' }
	lance.res.end JSON.stringify obj

lance.serve.redirect = (path = '') ->
	lance.res.writeHead 302, { 'location': path, 'content-type': 'text/plain; charset=utf-8' }
	lance.res.end()

lance.serve.code	= (code, headers = { 'content-type': 'text/plain; charset=utf-8' }, body = '') ->
	lance.res.writeHead code, headers

	if body
		lance.res.end body
	else
		title = lance.httpCodes[ code.toString() ] or ''
		lance.res.end "#{code} #{title}"

lance.respond = (req, res, opt = {}) ->
	opt.encoding	= opt.encoding	or 'utf8'
	opt.code		= opt.code		or 500
	opt.headers		= opt.headers	or { 'content-type': 'text/html; charset=utf-8' }
	opt.body		= opt.body		or ''

	opt.headers['content-length'] = opt.body.length or 0

	for key, val of opt.headers
		res.setHeader key, val

	res.statusCode = opt.code

	res.end opt.body, opt.encoding

### compression. too mem-leaky and cpu intense, will pass.

		finalize = (req, res, body, done = ->) ->
			normalize = (err, body) ->
				if err then throw new Error err
				done body

			acceptEncoding = req.headers['accept-encoding'] or ''

			if acceptEncoding.match /\bgzip\b/i
				res.setHeader 'content-encoding', 'gzip'
				zlib.gzip body, normalize
			else if acceptEncoding.match /\bdeflate\b/i
				res.setHeader 'content-encoding', 'deflate'
				zlib.deflate body, normalize
			else

			res.setHeader 'content-length', body.length
			done body

			return true
###

