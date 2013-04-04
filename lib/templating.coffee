
path	= require 'path'
fs		= require 'fs'
cluster	= require 'cluster'

lance = require './lance'

{clone, merge}	= Object
{type, isAbsolute, changeExt, isExt, exploreDir} = Function

template	=
ect			=
coffee		=
stylus		=
toffee		=
cfg			= {}

lance.templating = {
	# vars

	cfg: {}

	templates: {
		compiled	: {}
		files		: {}
	}

	mergeCache: {
		coffee: {}
		stylus: {}
	}

	watching: {
		templates	: {}
		stylus		: {}
		coffee		: {}
	}

	locals: {}

	# functions

	resolveDir: (dir, root = '') -> if isAbsolute( dir ) then dir else path.join root or cfg.root, dir

	# initialization

	init: (root, newCfg = {}) ->
		if type( arguments[0] ) is 'object'
			newCfg	= arguments[0]
			root	= ''

		# set module-scope variables
		cfg		= clone lance.cfg.templating or {}
		@cfg	= cfg

		merge cfg, newCfg # max depth of 2, for objects

		cfg.root = root or cfg.root or lance.rootDir

		stylus		= cfg.stylus
		coffee		= cfg.coffee
		ect			= cfg.ect
		toffee		= cfg.toffee
		template	= cfg.template
		
		stylus.engine	= stylus.engine		or false
		coffee.engine	= coffee.engine		or require 'coffee-script'
		toffee.engine	= toffee.engine		or false
		ect.engine		= ect.engine		or false
		
		try if not stylus.engine	and require.resolve 'stylus'	then stylus.engine	= require 'stylus'
		try if not ect.engine		and require.resolve 'ect'		then ect.engine		= require 'ect'
		try if not toffee.engine	and require.resolve 'toffee'	then toffee.engine	= require 'toffee'

		# initialize ect

		if type( ect.engine ) is 'function'
			if ect.findIn
				ect.options.root = path.join cfg.root, ect.findIn
			else
				ect.options.root = ect.options.root or cfg.root

			ect.options.ext	= ect.options.ext or ect.ext
			ect.engine		= ect.engine ect.options

		ect.ext	= ect.ext or ect.options.ext or ''

		# initialize toffee

		if type( toffee.engine ) is 'function'
			toffee.engine = new( toffee.engine toffee.options )

		toffee.findIn = path.join cfg.root, toffee.findIn

		@build()
		@watch() if cluster.isMaster

		return true

	# merged renders

	addMerged: (mergeCache, fileDir, rendered) ->
		return false if not fileDir or not rendered?

		# will group filenames like:
		# (app)-main.coffee, (app)-appendix.coffee		as app.coffee
		# 1-main.coffee, 1-appendix.coffee				as 1.coffee
		match = path.basename( fileDir ).match ///
			^
			( \d+ | \( [^\)]+ \) )
			[\-]
		///i

		return false if not match or not match[1]

		if group = match[1]
			group = group.replace /^\(|\)$/g, '' # trim surrounding round brackets

			if not ( group of mergeCache ) then mergeCache[group] = {}
			mergeCache[group][fileDir] = rendered

			return true

		return false

	renderMergedCoffee: ->
		return false if Function.empty @mergeCache.coffee

		for groupName, group of @mergeCache.coffee
			merged	= ''
			keys	= Object.keys( group ).sort()

			continue if not keys.length

			for fileDir in keys
				rendered = group[fileDir]

				merged += "\n/* #{path.basename fileDir} */"
				merged += '\n' + rendered + '\n'

			renderTo	= @resolveDir coffee.renderTo

			newFileDir	= path.join renderTo, "#{groupName}.js"

			fs.writeFile newFileDir, merged

		return merged

	renderMergedStylus: ->
		return false if Function.empty @mergeCache.stylus

		for groupName, group of @mergeCache.stylus
			merged	= ''
			keys	= Object.keys( group ).sort()

			continue if not keys.length

			for fileDir in keys
				rendered = group[fileDir]

				merged += "\n/* #{path.basename fileDir} */"
				merged += '\n' + rendered + '\n'

			renderTo	= @resolveDir stylus.renderTo

			newFileDir	= path.join renderTo, "#{groupName}.css"

			fs.writeFile newFileDir, merged

		return merged

	# rendering

	renderStylus: (fileDir) ->
		return false if not stylus.engine

		fileDir = @resolveDir fileDir

		if not fs.existsSync fileDir
			lance.error 'Notice', 'templating.renderStylus', "'#{fileDir}' doesnt exist; ignoring"
			return false

		file = fs.readFileSync fileDir, 'utf8'

		if not file?
			lance.error 'Warning', 'templating.renderStylus', "'#{fileDir}' not readable"
			return false

		engine = stylus.engine file
		engine.set 'paths', [ path.dirname fileDir ]
		engine.render (err, rendered) =>
			if err
				lance.error 'Error', 'templating.renderStylus -> stylus.engine.render', err
				return false

			renderTo	= @resolveDir stylus.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext

			newFileDir	= path.join renderTo, name + '.css'

			if stylus.minify then rendered = String.minifyCss rendered

			if not ( @addMerged @mergeCache.stylus, fileDir, rendered )
				fs.writeFile newFileDir, rendered
			else
				@renderMergedStylus()

		return true

	renderCoffee: (fileDir) ->
		fileDir = @resolveDir fileDir

		if not fs.existsSync fileDir
			lance.error 'Notice', 'templating.renderCoffee', "'#{fileDir}' doesnt exist; ignoring"
			return false

		file = fs.readFileSync fileDir, 'utf8'

		if not file?
			lance.error 'Warning', 'templating.renderCoffee', "'#{fileDir}' not readable"
			return false

		rendered	= coffee.engine.compile file

		renderTo	= @resolveDir coffee.renderTo
		ext			= path.extname fileDir
		name		= path.basename fileDir, ext
		newFileDir	= path.join renderTo, name + '.js'

		if coffee.minify then rendered = String.minifyJs rendered

		if not @addMerged @mergeCache.coffee, fileDir, rendered
			fs.writeFile newFileDir, rendered
		else
			@renderMergedCoffee()

		return true

	renderToffee: (dir, locals = {}, callback) ->
		if not toffee.engine then return callback 'Toffee is not loaded', null

		# throw in __toffee options to specify the right dir path
		locals.__toffee	= locals.__toffee or {}
		if toffee.findIn then locals.__toffee.dir = locals.__toffee.dir or toffee.findIn

		# make sure it has [a / the right] extension
		if toffee.ext then dir = changeExt dir, toffee.ext

		toffee.engine.render dir, locals, (err, rendered) ->
			if toffee.minify then rendered = String.minify rendered

			callback err, rendered

		return true

	renderEct: (dir, locals = {}, callback) ->
		if not ect.engine then return callback 'Ect is not loaded', null

		ect.engine.render dir, locals, (err, rendered) ->
			if ect.minify then rendered = String.minify rendered

			callback err, rendered

		return true

	renderTemplate: (fileDir, locals = {}, callback) ->
		if not template.engine then callback 'Template engine invalid', null

		fileDir = @resolveDir fileDir

		if not fileDir of @templates.compiled
			@compileTemplate fileDir, locals

		compiled = @templates.compiled[fileDir]
		rendered = compiled locals

		if template.minify then rendered = String.minify rendered

		callback null, rendered

	# compiling

	compileTemplate: (fileDir, locals = {}) ->
		return false if not template.engine

		fileDir = @resolveDir fileDir

		if not fileDir of @templates.files
			return lance.error 'Warning', 'templating.compileTemplate', "'#{fileDir}' is not loaded"

		file = @templates.files[fileDir]

		compiled = template.engine.compile file, locals

		@templates.compiled[fileDir] = compiled

		return compiled

	# watching
	watchStylus: (fileDir) ->
		if not @watching.stylus[fileDir]
			fs.watch fileDir, (event) =>
				return false if event isnt 'change'

				@renderStylus fileDir

			@watching.stylus[fileDir] = true

	watchCoffee: (fileDir) ->
		if not @watching.coffee[fileDir]
			fs.watch fileDir, (event) =>
				return false if event isnt 'change'

				@renderCoffee fileDir

				@watching.coffee[fileDir] = true

	watchTemplates: (fileDir) ->
		if not @watching.templates[fileDir]
			fs.watch fileDir, (event) =>
				return false if event isnt 'change'

				@compileTemplate fileDir

				@watching.templates[fileDir] = true

	# build/watch directory iteration and cumulative commands

	watch			: -> @build true, false
	buildAndWatch	: -> @build true, true

	build: (doWatch = false, doBuild = true) ->
		args = [stylus.findIn, coffee.findIn, template.findIn]

		if doBuild then @mergeCache = clone defaultMergeCache # cleans the mergeCache out

		for arg in args
			continue if not arg

			if type( arg ) is 'string' then arg = [arg]

			done = []

			for dir in arg
				dir = @resolveDir dir

				if dir in done
					continue

				done.push dir

				exploreDir dir, (file, fileDir, fileName, name, ext) =>
					if isExt ext, stylus.ext
						@renderStylus fileDir		if doBuild
						@watchStylus fileDir		if doWatch

					if isExt ext, coffee.ext
						@renderCoffee fileDir		if doBuild
						@watchCoffee fileDir		if doWatch

					if isExt ext, template.ext
						@templates.files[fileDir] = file

						@compileTemplate fileDir	if doBuild
						@watchTemplates fileDir		if doWatch

		return true
}

defaultMergeCache = clone lance.templating.mergeCache

lance.templating.render = lance.templating.renderEct

