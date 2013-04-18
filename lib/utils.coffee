
fs		= require 'fs'
path	= require 'path'
lance	= require './lance'

typeTable = {
	'Boolean'	: Boolean
	'Number'	: Number
	'String'	: String
	'Function'	: Function
	'Array'		: Array
	'Date'		: Date
	'RegExp'	: RegExp
	'Object'	: Object
	'Undefined'	: undefined
	'Null'		: null
	'NaN'		: NaN
}

module.exports	=
lance.utils		=
utils			= {
	# Returns variable type as string
	typeOf: (vari) ->
		for type of typeTable
			if "[object #{type}]" is Object::toString.call vari
				return type.toLowerCase()

		return 'null'

	# Checks for object or array type
	isIterable: (vari) ->
		type = utils.typeOf vari

		return type is 'object' or type is 'array'

	# Compares two file extensions
	isExt: (fileDir, ext) ->
		return false if not fileDir or not ext

		if ext?
			ext		= ext.replace(/^\./, '')
			regex	= new RegExp('.' + ext + '$', 'i')
		else
			regex	= /\.[^\.]+$/

		return fileDir.match regex
	
	# Dertermines if a string matches as an absolute directory
	isAbsolute: (fileDir) ->
		return false if not fileDir

		return fileDir.match /^(\/|\w:)/

	# Determines if a variable evalutes to false or empty
	empty: (vari, depth = 5) ->
		return true if depth < 1

		if utils.isIterable vari
			for key, val of vari
				if utils.isIterable val
					return false if not arguments.callee val, depth - 1
				else
					return false if val

			return true

		return ! vari

	# Explores a directory and subdirectories.
	exploreDir: (dir, opt = {}) ->
		return false if not dir

		explore = (dir, opt) =>
			return false if opt.depth < 1

			for filename in fs.readdirSync dir
				ext			= path.extname filename
				name		= path.basename filename, ext
				filepath	= path.resolve path.join dir, filename
				stats		= fs.statSync filepath
				
				continue if	filename[0] is opt.ignoreChar or not stats

				if stats.isDirectory()
					if opt.onFolder
						if ( opt.onFolder filepath ) isnt false
							arguments.callee filepath, opt
					else
						arguments.callee filepath, opt
					
				else if stats.isFile()
					file = fs.readFileSync filepath, 'utf8'

					if opt.onFile
						if opt.onFile( file, filepath, filename, name, ext ) is false
							break
		
		if utils.typeOf( opt ) is 'function'
			opt = { onFile: opt }

		opt.onFile		= opt.onFile		or false
		opt.onFolder	= opt.onFolder		or false
		opt.ignoreChar	= opt.ignoreChar	or '_'
		opt.depth		= opt.depth			or 6

		return explore dir, opt

	# Change an extension of a file path
	changeExt: (dir, ext = '') ->
		return dir if not dir

		ext = ext.replace /^\./, ''
		ext = '.' + ext if ext

		return dir.replace /\.[^\.]+$|$/, ext

	# Minify a string, such as html
	minify: (str) ->
		return str
			.replace(/^\s+|\s+$/gm, '')
			.replace(/\n/g, '')
			.replace(/\s{2,}/g, ' ')

	# Minify CSS
	minifyCss: (str) ->
		return str
			.replace(/^\s+|\s+$/gm, '')
			.replace(///
					\n
				|	\s+(?=\{)
				|	\;\s*(?=\})
			///g, '')
			.replace(/\s{2,}/g, ' ')
			.replace(/\s*\:\s+/g, ':')
			.replace(/\{\s+/g, '{')
			.replace(/\s+\}/g, '}')

	# Clone an object
	clone: (obj) ->
		return utils.merge {}, obj

	# Merge obj1 by replacing values in obj1 with those from obj2. Iterates nested objects.
	merge: (obj1, obj2, depth = 8) ->
		merge = (obj1, obj2, depth) ->
			if depth >= 1
				for own key of obj2
					if (
						utils.typeOf( obj2[key] ) is 'object' and
						obj1[key] and
						utils.typeOf( obj1[key] ) is 'object'
					)
						arguments.callee obj1[key], obj2[key], depth - 1
					else
						obj1[key] = obj2[key]

		merge obj1, obj2, depth
		return obj1
	
	# Convert an object to an array. Especially useful when considering the "arguments" pseudo-array variable
	toArray: (args, sort = false) ->
		ary = Array::slice.call args
		
		if sort
			if utils.typeOf( sort ) is 'function'
				ary = ary.sort sort
			else
				ary = ary.sort()
				
		return ary
}
