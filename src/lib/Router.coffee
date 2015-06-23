Emitter = require('events').EventEmitter

{ clone, merge, typeOf } = require '../utils'

module.exports = class Router extends Emitter
	constructor: (newCfg, @lance) ->
		@cfg = clone require('../config').router

		merge @cfg, newCfg if newCfg

		@routes			= {}
		@namedRoutes	= {}
		@indexes		= {}

		@defaultResult =
			path		: {}
			splats		: []
			name		: ''
			callback	: false
			pattern		: ''
			regex		: null

		for method in @methods
			@routes[ method ]	= []
			@indexes[ method ]	= {}

	methods: [ 'get', 'post', 'head', 'put', 'delete', 'trace', 'connect', 'options', 'patch' ]

	# adds get() post() HEAD() etc. shortcut functions to the prototype
	for method in @::methods then do (method) =>
		@::[ method ]				=
		@::[ method.toUpperCase() ]	= (patterns, name, callback) -> @route method, patterns, name, callback

	all: (patterns, name, callback) ->
		for method in @methods
			@route method, patterns, name, callback

		return null
		
	@::['*'] = @::all

	add: (method, pattern, name, callback) ->
		keys	= []
		regex	= pattern
		
		if typeof regex is 'string'
			regex = @patternToRegex pattern, keys
		
		pattern = ( pattern or '' ).toString()
		
		index = @routes[ method ].length + 1

		route = {
			name: name or index
			callback
			regex
			pattern
			keys
		}
		
		@routes[method].push route

		@namedRoutes[ name or pattern ] = route
		
		@emit 'route', route

		return route

	route: (method, patterns, name = '', callback = ->) ->
		if typeOf.Array args = method
			return @[ args[0] ]? args[1..]...
			
		return false if not patterns or not method

		method = method.toLowerCase()

		if method not of @routes
			@lance.emit 'err', new Error "`#{method}` method is unsupported/invalid"
			return false

		if returnFirst = typeOf.String patterns
			patterns = [ patterns ]
		
		# allows for name and callback to be either a string or function
		if typeOf.Function name
			callback	= name
			name		= ''

		results = ( @add method, pattern, name, callback for pattern in patterns )

		return if returnFirst then results[0] else results

	match: (urlPath = '', method = 'get', skipTo = 0) ->
		if not urlPath
			@lance.emit 'err', new Error "`#{urlPath}` urlPath is invalid", 'Lance.Router.match'
			return @defaultResult

		method = method.toLowerCase()

		if @routes[ method ] is undefined
			@lance.emit 'err', new Error "`#{method}` method is unsupported/invalid", 'Lance.Router.match'
			return @defaultResult
			
		@emit 'matching', urlPath, method, skipTo

		indexPath = "#{skipTo}:#{urlPath}"

		# if the path has been routed before and is thus indexed we can skip processing
		###
			TODO: make this on by default and more robust:
			It needs to first contain all matching steps in a route, not just the endpoint.
			The result should only count "o.next()" calls though, although it may already do that.
		###
		if @cfg.cache and @indexes[ method ][ indexPath ] isnt undefined
			return @indexes[ method ][ indexPath ]
		
		# process a result
		for route, index in @routes[ method ]
			continue if skipTo > index

			path	= {}
			splats	= []
			
			captures = urlPath.match route.regex

			continue if not captures or captures.length < 1
			
			captures = captures[1..]
			
			for val, key in captures
				varName = route.keys[ key ]

				val = ( val or '' ).toString()

				try val = decodeURIComponent val
				
				if varName
					path[ varName ] = val
				else
					splats.push val

			result = {
				index
				path		: path
				splats		: splats
				name		: route.name
				callback	: route.callback
				pattern		: route.pattern
				regex		: route.regex
			}
			
			@emit 'matched', result

			# index the route
			if @cfg.cache
				@indexes[ method ][ indexPath ] = result

			return result

		return @defaultResult

	patternToRegex: (pattern, keys) ->
		pattern = pattern
			.concat('/?')
			.replace(
				/\/\(/g
				'(?:/'
			)
			.replace(
				///
					(/)?
					(\.)?
					:(\w+)
					(\(.*?\))?
					(\?)?
				///g
				(match, slash, format, key, rematch, optional) ->
					keys.push key

					slash		= slash		or ''
					optional	= optional	or ''
					rematch		= rematch	or '([^/]+?)'
					format		= format	or ''

					result = ''
					result += slash if ! optional
					result += '(?:'
					result += slash if optional
					result += format + rematch + ')' + optional

					return result
			)
			.replace(
				/([\/.])/g
				(match, str) ->
					return '\\' + str
			)
			.replace(
				/\*/g
				'(.+)'
			)

		return new RegExp "^#{pattern}$", 'i'

