
path	= require 'path'
fs		= require 'fs'

clone	=
merge	=
cfg		= undefined

defaultCfg = {
	include			: []
	exclude			: []
	globalInclude	: []
	globalExclude	: ['node_modules']
	root			: ''
	depth			: 10
	wrap			: false
	extensions		: false
	readFiles		: false
	onlyReadFiles	: false
	paths			: true
	pathedKeys		: false # to be implimented ( easy )
}

requirer = {
	build: (dir) ->
		build = (dir, include, exclude, depth) =>
			folder	= {}
			paths	= {}

			if cfg.wrap
				unwrapper = @unwrapper

				# an unwrapper function for each folder
				folder['_unwrap'] = do (unwrapper) ->
					return (doChildren) -> unwrapper this, doChildren

			result = null

			return folder if depth < 1

			for filename in fs.readdirSync dir
				ext			= path.extname filename
				name		= path.basename filename, ext
				filepath	= path.resolve path.join dir, filename
				stats		= fs.statSync filepath

				continue if	( filename[0] is '_' or name in exclude or filename in exclude ) or
							( include.length and ! ( name in include and filename in include ) ) or
							! stats
				
				key = name
				key = filename if cfg.extensions

				if stats.isDirectory()
					folder[key]		= arguments.callee filepath, cfg.globalInclude, cfg.globalExclude, depth - 1
					paths['_this']	= dir

				else if stats.isFile()
					if ! cfg.onlyReadFiles and ext of require.extensions
						if cfg.wrap
							# wraps the file in a function to wrap execution
							folder[key] = do (filepath) ->
								return () -> require filepath
						else
							folder[key] = require filepath

					else if cfg.onlyReadFiles or cfg.readFiles
						folder[key] = fs.readFileSync filepath, 'utf8'

				paths[key] = filepath

				if cfg.paths
					folder['_paths'] = paths

			return folder
			
		include	= cfg.include.concat cfg.globalInclude
		exclude	= cfg.exclude.concat cfg.globalExclude
		
		return build dir, include, exclude, cfg.depth
		

	unwrapper: (obj, doChildren = true) ->
		unwrap = (obj, doChildren = true) ->
			return obj if ! '_unwrap' of obj
			delete obj['_unwrap']

			for key, item of obj
				continue if key[0] is '_'

				if doChildren
					if ( Function.type item ) is 'object' and '_unwrap' of item
						arguments.callee item, true
						continue

				if ( Function.type item ) is 'function'
					obj[key] = item()

			return obj

		return unwrap obj, doChildren
		

	formatPath: (dir, filename) ->
		dir = path.join dir, filename
		pathname = dir.replace cfg.root, ''
		pathname = pathname.replace /[\\]/g, '/'
		pathname = pathname.replace(/^\/|\/$/g, '')

		return pathname
}


exports = (dir, newCfg = {}) ->
	{clone, merge} = Object
	
	if ( Function.type arguments[0] ) is 'object'
		newCfg	= arguments[0]
		dir		= null

	dir = process.env.startdir if ! dir

	cfg = clone defaultCfg

	merge cfg, newCfg
	
	if fs.existsSync dir
		return requirer.build dir
	else
		console.log ">> Warning, requirer: [ #{dir} ] doesnt exist"
		return {}
	

module.exports = exports
