
lance = require './lance'

{clone, merge, typeOf, toArray}	= lance.utils

defaultResult = {
	path		: {}
	splats		: []
	name		: ''
	callback	: false
	pattern		: ''
}

router			=
lance.router	= {
	add: (method, pattern, name, callback) ->
		keys	= []
		regex	= pattern
		
		if typeof regex is 'string'
			regex = router.patternToRegex pattern, keys
		
		pattern = pattern.toString()
		
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
			lance.error {
				type	: 'warning'
				scope	: 'lance.router.add'
				error	: new Error "#{method} method is unsupported/invalid"
			}
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

	match: (urlPath = '', method = 'get') ->
		if not urlPath or typeof urlPath isnt 'string'
			lance.error {
				type	: 'warning'
				scope	: 'lance.router.match'
				error	: new Error "#{urlPath} urlPath is invalid"
			}
			return defaultResult

		method = method.toLowerCase()

		if method not of router.routes
			lance.error {
				type	: 'warning'
				scope	: 'lance.router.match'
				error	: new Error "'#{method}' method is unsupported/invalid"
			}
			return defaultResult

		# if the path has been routed before and is thus indexed we can skip processing
		if lance.cfg.router.cache and urlPath of router.indexes
			return indexes[method][urlPath]
				
		# process a result
		for route in router.routes[method]
			path	= {}
			splats	= []
			
			captures = urlPath.match route.regex

			continue if not captures or captures.length < 1
			
			captures = captures[1..]
			
			for val, key in captures
				varName = route.keys[key] or ''
				
				val = decodeURIComponent val.toString()
				
				if varName
					path[varName] = val
				else
					splats.push val

			result = {
				routes		: router.namedRoutes
				path		: path
				splats		: splats
				name		: route.name
				callback	: route.callback
				pattern		: route.pattern
				regex		: route.regex
			}
			
			# index the route
			if lance.cfg.router.cache
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
}

for _method in ['get', 'post', 'head', 'put', 'delete', 'trace', 'connect', 'options']
	do (_method) ->
		router[_method]					=
		router[_method.toUpperCase()]	= (patterns, name, callback = ->) ->
			router.route _method, patterns, name, callback

	router.routes[_method] = []
	router.indexes[_method] = {}

