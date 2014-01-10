
L = require './lance'

{clone, merge, typeOf, toArray}	= L.utils

defaultResult = {
	routes		: {}
	path		: {}
	splats		: []
	name		: ''
	callback	: false
	pattern		: ''
	regex		: null
}

module.exports	=
router			= {
	add: (method, pattern, name, callback) ->
		keys	= []
		regex	= pattern
		
		if typeof regex is 'string'
			regex = router.patternToRegex pattern, keys
		
		pattern = (pattern or '').toString()
		
		index = router.routes[method].length + 1

		route = {
			name: name or index
			callback
			regex
			pattern
			keys
		}
		
		router.routes[method].push route

		# TODO: extend namedRoutes to be all arrays, or only arrays when there are two items
		router.namedRoutes[name or pattern] = route

		return route

	route: (method, patterns, name = '', callback = ->) ->
		return false if not patterns or not method

		method = method.toLowerCase()

		if method not of router.routes
			L.error(
				'L.router.route'
				new Error "#{method} method is unsupported/invalid"
			)
			return false

		args = toArray arguments
		
		if returnFirst = typeof patterns is 'string'
			patterns = [ patterns ]
		
		# allows for name and callback to be either a string or function
		if typeOf( args[2] ) is 'function'
			callback	= args[2]
			name		= ''

		results = []
		for pattern in patterns
			results.push router.add method, pattern, name, callback

		if returnFirst
			return results[0]
		else
			return results

	match: (urlPath = '', method = 'get', skipTo = 0) ->
		if not urlPath or typeof urlPath isnt 'string'
			L.error(
				'L.router.match'
				new Error "#{urlPath} urlPath is invalid"
			)
			return defaultResult

		routes	= router.routes
		method	= method.toLowerCase()

		if method not of routes
			L.error(
				'L.router.match'
				new Error "'#{method}' method is unsupported/invalid"
			)
			return defaultResult

		# if the path has been routed before and is thus indexed we can skip processing
		if false and L.cfg.router.cache and urlPath of router.indexes[method]
			return router.indexes[method][urlPath]
				
		# process a result
		for route, index in routes[method]
			continue if skipTo > index

			path	= {}
			splats	= []
			
			captures = urlPath.match route.regex

			continue if not captures or captures.length < 1
			
			captures = captures[1..]
			
			for val, key in captures
				varName = route.keys[key] or ''

				val = (val or '').toString()

				try val = decodeURIComponent val
				
				if varName
					path[varName] = val
				else
					splats.push val

			result = {
				index
				routes		: router.namedRoutes
				path		: path
				splats		: splats
				name		: route.name
				callback	: route.callback
				pattern		: route.pattern
				regex		: route.regex
			}

			# index the route
			if L.cfg.router.cache
				router.indexes[method][urlPath] = result

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

	routes		: {}
	namedRoutes	: {}
	indexes		: {}
	methods		: ['get', 'post', 'head', 'put', 'delete', 'trace', 'connect', 'options']
}


for method in router.methods
	do (method) ->
		router[method]					=
		router[method.toUpperCase()]	= (patterns, name, callback) ->
			router.route method, patterns, name, callback

	router.routes[method] = []
	router.indexes[method] = {}

router.all = (patterns, name, callback) ->
	for method in router.methods
		router.route method, patterns, name, callback

	return null

