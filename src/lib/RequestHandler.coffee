Promise			= require 'bluebird'
Cookies			= require 'cookies'
Busboy			= require 'busboy'
path			= require 'path'
os				= require 'os'
fs				= require 'fs'
parseUrl		= require('url').parse
querystring		= require 'querystring'
zlib			= require 'zlib'
crypto			= require 'crypto'
transposer		= new ( require('transposer') )

{ merge, typeOf, clone, coroutiner } = require '../utils'

module.exports = coroutiner class RequestHandler
	constructor: (@req, @res, @lance) ->
		@time			= new Date()
		@code			= 200
		@headers		= { 'content-type': 'text/html; charset=utf-8' }
		@body			= ''
		@json			= {}
		@template		= { view: '', data: {}, templater: @lance.templater }
		@redirect		= ''
		@redirectQuery	= {}
		@query			= {}
		
		@serve.redirect	= @serveRedirect
		@serve.template	= @serveTemplate
		@serve.json		= @serveJson
		@serve.code		= @serveHttpCode
				
		@lance.emit 'request.unparsed', this

	serve: (template) =>
		merge @template, template if template
		
		try
			@lance.emit 'serve', this

			if @redirect
				@serve.redirect()
			else
				if @template.view
					@serve.template()
				else
					@serve.json()
		catch err
			@lance.emit 'err', err
			@serve.code 500
	
	serveTemplate: (view = @template.view, data = @template.data) =>
		try
			@lance.emit 'serveTemplate', this
			@lance.emit 'serve.template', this

			if view
				data = merge {
					@query
					o: {
						@time, @code, @headers, @body, @encoding, @json, @template, @redirect
						@redirectQuery, @query, @method, @route, @path, @splats, @cookies
						@files, @session
					}
				}, data

				rendered = yield @template.templater.render view, data

				@body = rendered

			yield return @respond()

		catch err
			@lance.emit 'err', err
			@serve.code 500

		yield return

	serveJson: (json) =>
		@lance.emit 'serveJson', this
		@lance.emit 'serve.json', this

		@res.statusCode = @code
		@res.setHeader 'content-type', 'application/json'
		@res.end JSON.stringify json or @json

	serveRedirect: (path = @redirect, query = @redirectQuery) =>
		@lance.emit 'serveRedirect', this
		@lance.emit 'serve.redirect', this

		if hash = path.match( /(#[\w\d_-]+)/i )?[1]
			path = path.replace hash, ''

		if Object.keys( query ).length
			path += '?' + querystring.stringify query

		if hash
			path += hash

		@res.statusCode = 302
		@res.setHeader 'location', path
		@res.end()

	serveHttpCode: (code = @code, body = '', headers = { 'content-type': 'text/plain; charset=utf-8' }) =>
		@lance.emit 'serveHttpCode', this
		@lance.emit 'serve.code', this

		@res.statusCode = code
		@res.setHeader key, val for key, val of headers

		if body
			@res.end body
		else
			title = @lance.data.httpcodes[ code.toString() ] or ''
			@res.end "#{code} #{title}"
			
	parse: ->
		@lance.emit 'request.parse', this

		yield @parseRequest()

		@lance.emit 'request', this
		
		if @route.callback
			@route.callback.apply @lance, [ this ]
		else
			@lance.requestCallback.apply @lance, [ this ]

		yield return this

	respond: ->
		@lance.emit 'respond', this
		
		@res.statusCode = @code
		@res.setHeader key, val for key, val of @headers

		stream = new require('stream').Readable()
		switch type = typeOf @body
			when 'string'
				stream.push @body
				stream.push null
			else
				stream.pipe @body
		
		if @lance.cfg.server.compress
			if compressor = @compress()
				stream = stream.pipe compressor
			
		if not compressor?
			length = Buffer.byteLength @body.toString(), 'utf8'
			@res.setHeader 'content-length', length or 0
		
		stream.pipe @res

	compress: ->
		acceptEncoding = @req.headers['accept-encoding'] or ''
		
		if acceptEncoding.match /\bgzip\b/i
			@res.setHeader 'content-encoding', 'gzip'
			return zlib.createGzip @lance.cfg.compress.createGzip
		else if acceptEncoding.match /\bdeflate\b/i
			@res.setHeader 'content-encoding', 'deflate'
			return zlib.createDeflate @lance.cfg.compress.createDeflate
		else
			return null
				
	compressSync: (body) ->
		acceptEncoding = @req.headers['accept-encoding'] or ''

		new Promise (resolve, reject) ->
			handler = (err, body) ->
				return reject err if err
				return resolve body
				
			if acceptEncoding.match /\bgzip\b/i
				@res.setHeader 'content-encoding', 'gzip'
				zlib.gzip body, handler
			else if acceptEncoding.match /\bdeflate\b/i
				@res.setHeader 'content-encoding', 'deflate'
				zlib.deflate body, handler
			else
				@res.setHeader 'content-length', body.length or 0
				resolve body
	next: ->
		url = @route.url

		newRoute		= @lance.router.match url.pathname, @method, @route.index + 1
		newRoute.url	= url

		@route		= newRoute
		@path		= newRoute.path
		@splats		= newRoute.splats

		if newRoute.callback
			newRoute.callback this

		return this
		
	setQueryField: (data, field, value) ->
		if field of data
			if not typeOf.Array data[ field ]
				data[ field ] = [ data[ field ] ]
				
			data[ field ].push value
		else
			data[ field ] = value
			
	handleFile: (field, stream, filename, encoding, mimetype) ->
		fileExt = path.extname( filename )[1..]
		mimeExt = ''
		
		if @lance.data.mimetypes[ fileExt ] is mimetype
			mimeExt = fileExt
		else
			for ext, type of @lance.data.mimetypes when type is mimetype
				mimeExt = ext
				
				break

		if not filename or not mimeExt or stream.truncated
			stream.resume()
			return null
			
		newFileName		= new Date().getTime() +  crypto.randomBytes(2).toString('hex') + '.' + mimeExt
		tempFilePath	= path.join os.tmpDir(), newFileName
		length			= 0
		timeout			= null
		
		deleteFile = -> new Promise (resolve) ->
			clearTimeout timeout
			fs.exists tempFilePath, (exists) ->
				if exists
					fs.unlink tempFilePath, resolve
				else
					resolve()

		@setQueryField @files, field, {
			field
			filename
			encoding
			mimetype
			file		: tempFilePath
			truncated	: stream?.truncated
			ext			: mimeExt
			delete		: deleteFile
		}
		
		timeout = setTimeout deleteFile, @lance.cfg.server.tempTimeout

		return new Promise (resolve, reject) ->
			writeStream = fs.createWriteStream tempFilePath
				.on 'finish', resolve
				.on 'error', reject
			
			stream.pipe writeStream
		
	parseDataFallback: ->
		postBody = ''
		yield new Promise (resolve, reject) =>
			@req.on 'data', (chunk) -> postBody += chunk
			@req.on 'end', =>
				@query = querystring.parse( postBody ) or {}
				resolve()
	
	parseData: ->
		@query	= {}
		@files	= {}
		
		postBody	= ''
		
		yield return switch @method
			when 'GET'
				@query = @route.url.query or {}
			else
				options = clone @lance.cfg.server.busboy
				merge options, { headers: @req.headers }
				
				new Promise (resolve, reject) =>
					try
						@stream = new Busboy options
					catch err
						return resolve @parseDataFallback()
					
					awaiting = []
					@stream.on 'file', =>
						awaiting.push @handleFile.apply this, arguments

					@stream.on 'field', (field, value, truncatedField, truncatedVal) =>
						@setQueryField @query, field, value
					
					@stream.on 'finish', =>
						resolve Promise.all awaiting
					
					@req.pipe @stream
					

	parseRequest: ->
		@method		= @req.method.toUpperCase()

		url			= parseUrl @req.url, true
		@route		= @lance.router.match url.pathname, @method
		@route.url	= url

		@path		= @route.path
		@splats		= @route.splats

		@cookies	= new Cookies @req, @res

		yield @parseData()
		yield return @query = transposer.transposeAll @query
		
