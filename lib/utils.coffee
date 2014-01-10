
fs		= require 'fs'
path	= require 'path'

module.exports	=
utils			= {}

# Returns variable type as string
utils.typeOf = (vari) ->
	t = typeof vari

	if t is 'undefined' or t is 'string' or t is 'function' or t is 'boolean'
		return t 

	return 'array' if Array.isArray vari

	for type of typeTable
		if "[object #{type}]" is Object::toString.call vari
			return type.toLowerCase()

	return 'null'

utils.sort = (aryObj) ->
	fields = Array::slice.apply(arguments)[1..]
	
	for field in fields
		if not utils.typeOf.Object field
			field = {
				key: field.toString()
			}
		
		field.order = !! ( field.order is 'asc' )
		field.key or field.key = ''
			
		do (field) -> aryObj.sort (a, b) ->
			lesserReturn = if field.order then -1 else 1
			greaterReturn = if field.order then 1 else -1
			
			val1 = a[field.key] or ''
			val2 = b[field.key] or ''
			
			return lesserReturn if val1 < val2
			return greaterReturn if val1 > val2

			return 0
			
	return aryObj

# Checks for object or array type
utils.isIterable = (vari) ->
	t = utils.typeOf vari

	return t is 'object' or t is 'array'

utils.getLength = (vari) ->
	t = utils.typeOf vari

	if t is 'array' or t is 'string'
		return vari.length
	else if t is 'object'
		length = 0
		++length for item of vari
		return length
	else
		return 0

utils.isNumber = (n) ->
	return !isNaN( parseFloat(n) ) and isFinite(n)

utils.slugify = (str = '') ->
	str = decodeURIComponent str.toString('utf8')

	return str
		.toLowerCase()
		.replace( /[^a-z0-9-]+/g, '-' )
		.replace( /^[\s\-]+|[\s\-]+$/g, '' )

# Compares two file extensions
utils.isExt = (fileDir, ext) ->
	return false if not fileDir or not ext

	if ext?
		ext		= ext.replace(/^\./, '')
		regex	= new RegExp('.' + ext + '$', 'i')
	else
		regex	= /\.[^\.]+$/

	return fileDir.match regex

utils.isUrl = (str = '') ->
	return str.match ///^
		(
			(ht|f)tps?\://
		|	www\.
		)
		[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?
	///

# Dertermines if a string matches as an absolute directory
utils.isAbsolute = (fileDir) ->
	return false if not fileDir

	return fileDir.match /^(\/|\w:)/

# Determines if a variable evalutes to false or empty
# TODO: improve this so that it works on array n does some basic stuff
# could optimize by not using isiterable and instead getting typeOf once
utils.empty = (vari, depth = 5) ->
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
utils.exploreDir = (dir, opt = {}) ->
	return false if not dir or typeof dir isnt 'string'

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
utils.changeExt = (dir, ext = '') ->
	return dir if not dir

	ext = ext.replace /^\./, ''
	ext = '.' + ext if ext

	return dir.replace /\.[^\.]+$|$/, ext

# Minify a string, such as html
utils.minify = (str = '') ->
	return str
		.replace(/^\s+|\s+$/gm, '')
		.replace(/\n/g, '')
		.replace(/\s{2,}/g, ' ')

# Minify CSS
utils.minifyCss = (str = '') ->
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


utils.clone = (obj) ->
	try
		return utils.clone.json obj
	catch err
		return utils.clone.merge obj

utils.clone.json = (obj) ->
	return JSON.parse JSON.stringify obj

utils.clone.merge = (obj) ->
	return utils.merge {}, obj

utils.clone.array = (obj) ->
	return obj.slice(0)

Clone = ->

utils.clone.proto = (obj) ->
	Clone.prototype = obj
	return new Clone()

# Merge obj1 by replacing values in obj1 with those from obj2. Iterates nested objects.
utils.merge = (obj1, obj2, depth = 8) ->
	if depth > 0
		for own key of obj2
			obj2Type = utils.typeOf obj2[key]
			obj1Type = utils.typeOf obj1[key]
			if (
				( obj2Type is 'function' or obj2Type is 'object' ) and
				key of obj1 and
				( obj1Type is 'function' or obj1Type is 'object' )
			)
				arguments.callee obj1[key], obj2[key], depth - 1
			else
				obj1[key] = obj2[key]

	return obj1

utils.inspect = (vari, depth = 6, showHidden = true, colors = true) ->
	require('util').inspect vari, { depth, showHidden, colors }

utils.bind = (obj, binding = obj, depth = 6) ->
	if depth > 0
		for key, prop of obj
			do (key, prop, obj, binding, depth) ->
				switch utils.typeOf prop
					when 'function'
						prop	= utils.bind prop, binding, depth - 1
						newFn	= prop.bind binding

						utils.merge newFn, prop
						obj[key] = newFn
					when 'object'
						utils.bind prop, binding, depth - 1

	return obj

# Convert an object to an array. Especially useful when considering the "arguments" pseudo-array variable
utils.toArray = (args, sort = false) ->
	ary = Array::slice.call args
	
	if sort
		if utils.typeOf( sort ) is 'function'
			ary = ary.sort sort
		else
			ary = ary.sort()
			
	return ary


fullTypeTable = {
	'Undefined'	: undefined
	'Boolean'	: Boolean
	'String'	: String
	'Function'	: Function
	'Array'		: Array
	'Object'	: Object
	'Null'		: null
	'Number'	: Number
	'Date'		: Date
	'RegExp'	: RegExp
	'NaN'		: NaN
}

typeTable = {
	'Object'	: Object
	'Null'		: null
	'Number'	: Number
	'Date'		: Date
	'RegExp'	: RegExp
	'NaN'		: NaN
}

for key, val of fullTypeTable
	do (key) ->
		key2	= key
		key		= key.toLowerCase()

		utils.typeOf[key]	=
		utils.typeOf[key2]	= (vari) -> return utils.typeOf( vari ) is key

# Merge obj1 and obj2 by replacing values where both objects share the same keys, preffering obj1
utils.merge.by = (obj1, obj2, depth = 8, whiteList = true) ->
	if depth > 0
		for own key of ( if not whiteList then obj2 else obj1 )
			continue if ( not whiteList and key of obj1 ) or ( whiteList and key not of obj2 )

			obj2Type = utils.typeOf obj2[key]
			obj1Type = utils.typeOf obj1[key]

			if (
				( obj2Type is 'function' or obj2Type is 'object' ) and
				( obj1Type is 'function' or obj1Type is 'object' )
			)
				arguments.callee obj1[key], obj2[key], depth - 1
			else
				obj1[key] = obj2[key]

	return obj1

utils.merge.white = (obj1, obj2, depth) -> utils.merge.by obj1, obj2, depth, true
utils.merge.black = (obj1, obj2, depth) -> utils.merge.by obj1, obj2, depth, false
