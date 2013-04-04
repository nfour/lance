
# Note: This module extends its functionality to native objects; Object, String, Number etc.
# It does NOT extend prototypes. Instead only the globals; Object, Array etc.
fs			= require 'fs'
path		= require 'path'
requirer	= require './requirer'
lance		= require './lance'

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

lance.functions	=
functions		= {
	requirer: requirer
	util: require 'util'
	type: (vari) ->
		for type of typeTable
			if "[object #{type}]" is Object::toString.call vari
				return type.toLowerCase()

		return 'null'

	iterable: (vari) ->
		type = functions.type vari

		return type is 'object' or type is 'array'

	empty: (vari, depth = 5) ->
		return true if depth < 1

		if functions.iterable vari
			for key, val of vari
				if functions.iterable val
					return false if ! arguments.callee val, depth - 1
				else
					return false if val

			return true

		return ! vari

	extendPrototype: (fn, obj2) ->
		if ( functions.type fn ) is 'function'
			prototype = fn.prototype

			for own key, val of obj2
				continue if key of prototype
				prototype[key] = val

		return fn

	exploreDir: (dir, opt = {}) ->
		return false if ! dir

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
		
		if functions.type( opt ) is 'function'
			opt = { onFile: opt }

		opt.onFile		= opt.onFile		or false
		opt.onFolder	= opt.onFolder		or false
		opt.ignoreChar	= opt.ignoreChar	or '_'
		opt.depth		= opt.depth			or 6

		return explore dir, opt

	changeExt: (fileDir, ext = '') ->
		return fileDir if ! fileDir

		ext = ext.replace /^\./, ''
		ext = '.' + ext if ext

		return fileDir.replace /\.[^\.]+$|$/, ext

	isExt: (fileDir, ext) ->
		return false if ! fileDir? or ! ext?

		if ext?
			ext		= ext.replace(/^\./, '')
			regex	= new RegExp('.' + ext + '$', 'i')
		else
			regex	= /\.[^\.]+$/

		return fileDir.match regex
	
	isAbsolute: (fileDir) ->
		if fileDir
			return fileDir.match /^(\/|\w:)/
		else
			return false

	wrapper: (fn, newThis) ->
		return () -> fn.apply newThis, arguments

	String: {
		minify: (str) ->
			return str
				.replace(/^\s+|\s+$/gm, '')
				.replace(/\n/g, '')
				.replace(/\s{2,}/g, ' ')

		minifyCss: (str) ->
			return str
				.replace(/^\s+|\s+$/gm, '')
				.replace(///
						\n
					|	\s+(?=\{)
					|	\;\s*(?=\})
				///g, '')
				.replace(/\s{2,}/g, ' ')
				.replace(/\:\s+/g, ':')

		minifyJs: (str) ->
			return str
				.replace(/^\s+|\s+$/gm, '')
				.replace(/\n/g, '')
	}

	Object: {
		extendNatives: (obj) ->
			for own key, val of obj
				if key of typeTable
					continue if ( functions.type val ) isnt 'object'

					nativeObj = typeTable[key]

					for own _key, _val of val
						continue if _key of nativeObj
						nativeObj[_key] = _val
				else
					continue if key of Function
					Function[key] = val

			return true


		clone: (obj) ->
			return functions.Object.merge {}, obj

		merge: (obj1, obj2, depth = 8) ->
			if depth >= 1
				for own key of obj2
					if (
						functions.type( obj2[key] )  is 'object' and
						obj1[key] and
						functions.type( obj1[key] ) is 'object'
					)
						arguments.callee obj1[key], obj2[key], depth - 1
					else
						obj1[key] = obj2[key]

			return obj1
			
		toArray: (args, sort = false) ->
			ary = Array::slice.call( args )
			
			if sort
				if ( funcs.type sort ) is 'function'
					ary = ary.sort sort
				else
					ary = ary.sort()
					
			return ary
	}
}

# extends Object, Function etc.
functions.Object.extendNatives functions

module.exports	= lance.functions
