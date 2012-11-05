
require './functions'

{clone, merge, toArray}	= Object

lanceExports	= require 'lance'
{lance}			= lanceExports

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
	routes		: {}
	namedRoutes	: {}
	indexes		: {}
	
	add: (pattern, name, callback) ->
		keys	= []
		regex	= pattern
		
		if ( Function.type regex ) is 'string'
			regex = @patternToRegex pattern, keys
		
		pattern = pattern.toString()
		
		route = {
			name		: name or ''
			callback	: callback or false
			regex
			pattern	
			keys
		}
		
		@routes[pattern]				= route
		@namedRoutes[name or pattern]	= route

		return route
	
	match: (urlPath) ->
		# if the path has been routed before and is thus indexed we can skip processing
		if cfg.index and urlPath of @indexes
			return @indexes[urlPath]
				
		# process a result
		for own key, route of @routes
			path	= {}
			splats	= []
			
			captures = route.regex.exec urlPath

			continue if ! captures or captures.length < 1
			
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
				@indexes[urlPath] = result

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

exports = {
	cfg: cfg
	
	add: (patterns, name = '', callback = false) ->
		return false if ! patterns
		
		args = toArray arguments
		
		if returnFirst = ( Function.type patterns ) isnt 'array'
			patterns = [ patterns ]
		
		# allows for name and callback to be either a string or function
		if ( Function.type args[1] ) is 'function'
			callback = args[1]
			name = ''
		if ( Function.type args[2] ) is 'string'
			name = args[2]
				
		results = []
		for pattern in patterns
			results.push( router.add pattern, name, callback )

		if returnFirst
			return results[0]
		else
			return results
			
	match: (urlPath = '') ->
		if ! urlPath or ( Function.type urlPath) isnt 'string'
			console.log '>> Error, router.match: bad urlPath'
			return defaultResult
			
		return router.match urlPath
	
	routes		: router.routes
	namedRoutes	: router.namedRoutes
	indexes		: router.indexes
	
}

publicExports = {
	router: {
		cfg			: cfg
		add			: -> lance.router.add.apply		router, arguments
		match		: -> lance.router.match.apply	router, arguments
		routes		: router.routes
		namedRoutes	: router.namedRoutes
		indexes		: router.indexes
	}
	
	route: -> lance.router.add.apply lance.router, arguments

}

# extend lance

lance.router = exports

merge lanceExports, publicExports

module.exports = exports