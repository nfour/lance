
require './functions'

{clone, merge, toArray}	= Object
{type} = Function

lance = require './lance'

cfg = {
	index: true
}

defaultResult = {
	path		: {}
	splats		: []
	name		: ''
	callback	: false
	pattern		: ''
}

router = {
	routes		: {
		get		: []
		post	: []
		put		: []
		head	: []
		trace	: []
		delete	: []
		connect	: []
		options	: []
	}

	namedRoutes	: {}
	indexes		: {
		get		: {}
		post	: {}
		put		: {}
		head	: {}
		trace	: {}
		delete	: {}
		connect	: {}
		options	: []
	}
	
	add: (method, pattern, name, callback) ->
		keys	= []
		regex	= pattern
		
		if type( regex ) is 'string'
			regex = @patternToRegex pattern, keys
		
		pattern = pattern.toString()
		
		route = {
			name		: name or ''
			callback	: callback or false
			regex
			pattern
			keys
		}
		
		@routes[method].push route

		# TODO: extend namedRoutes to be all arrays, or only arrays when there are two items
		@namedRoutes[name or pattern] = route

		return route
	
	match: (method, urlPath) ->
		# if the path has been routed before and is thus indexed we can skip processing
		if cfg.index and urlPath of @indexes
			return @indexes[method][urlPath]
				
		# process a result
		for route in @routes[method]
			path	= {}
			splats	= []
			
			captures = route.regex.exec urlPath

			continue if not captures or captures.length < 1
			
			captures = captures[1..]
			
			for _val, _key in captures
				varName = route.keys[_key] or ''
				
				_val = decodeURIComponent _val.toString()
				
				if varName
					path[varName] = _val
				else
					splats.push _val

			result = {
				routes		: @namedRoutes
				path		: path
				splats		: splats
				name		: route.name
				callback	: route.callback
				pattern		: route.pattern
				regex		: route.regex
			}
			
			# index the route
			if cfg.index
				@indexes[method][urlPath] = result

			return result

		return defaultResult
			
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
}

lance.router = {
	cfg: cfg
	
	add: (method, patterns, name = '', callback = false) ->
		return false if not patterns or not method

		method = method.toLowerCase()

		if method not of router.routes
			lance.error 'Warning', 'router.add', "'#{method}' method is unsupported/invalid"
			return false

		args = toArray arguments
		
		if returnFirst = type( patterns ) isnt 'array'
			patterns = [ patterns ]
		
		# allows for name and callback to be either a string or function
		if type( args[1] ) is 'function'
			callback	= args[1]
			name		= ''

		if type( args[2] ) is 'string'
			name = args[2]
				
		results = []
		for pattern in patterns
			results.push( router.add method, pattern, name, callback )

		if returnFirst
			return results[0]
		else
			return results

	get		: (patterns, name, callback) -> @add 'get'		, patterns, name, callback
	post	: (patterns, name, callback) -> @add 'post'		, patterns, name, callback
	head	: (patterns, name, callback) -> @add 'head'		, patterns, name, callback
	put		: (patterns, name, callback) -> @add 'put'		, patterns, name, callback
	delete	: (patterns, name, callback) -> @add 'delete'	, patterns, name, callback
	trace	: (patterns, name, callback) -> @add 'trace'	, patterns, name, callback
	connect	: (patterns, name, callback) -> @add 'connect'	, patterns, name, callback
	options	: (patterns, name, callback) -> @add 'options'	, patterns, name, callback

	match: (urlPath = '', method) ->
		if not urlPath or type( urlPath ) isnt 'string'
			lance.error 'Warning', 'router.match', "'#{urlPath}' urlPath is invalid"
			return defaultResult

		method = method.toLowerCase()

		if method not of router.routes
			lance.error 'Warning', 'router.match', "'#{method}' method is unsupported/invalid"
			return defaultResult

		return router.match method, urlPath
	
	routes		: router.routes
	namedRoutes	: router.namedRoutes
	indexes		: router.indexes
}
