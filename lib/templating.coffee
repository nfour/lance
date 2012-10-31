
path	= require 'path'
fs		= require 'fs'

require './functions'
require './hooks'

{clone, merge}	= Object

lanceExports	= require 'lance'
lance			= lanceExports.lance

template	=
ect			=
coffee		=
stylus		=
cfg			= {}

templating = {
	# vars

	cfg: {}

	templates: {
		compiled	: {}
		files		: {}
	}

	watching: {
		templates	: {}
		stylus		: {}
		coffee		: {}
	}

	# functions

	resolveDir: (dir, root = '') ->
		return if Function.isAbsolute( dir ) then dir else path.join root or cfg.root, dir

	# initialization

	init: (root, newCfg = {}) ->
		if Function.type( arguments[0] ) is 'object'
			newCfg	= arguments[0]
			root	= ''

		# set module-scope variables
		cfg		= clone lance.project.cfg.lance.templating or {}
		@cfg	= cfg

		merge cfg, newCfg # max depth of 2, for objects

		cfg.root = cfg.root or root or process.env.startdir

		stylus		= cfg.stylus
		coffee		= cfg.coffee
		ect			= cfg.ect
		template	= cfg.template
		
		stylus.engine	= stylus.engine		or require('stylus') or false
		coffee.engine	= coffee.engine		or require 'coffee-script'
		ect.engine		= ect.engine		or require('ect') or false

		# initialize ect

		if Function.type( ect.engine ) is 'function'
			if ect.findIn
				ect.options.root = path.join cfg.root, ect.findIn
			else
				ect.options.root = ect.options.root or cfg.root

			ect.options.ext	= ect.options.ext or ect.ext

			ect.engine = ect.engine ect.options

		ect.ext	= ect.ext or ect.options.ext

		# watch

		@watch()
		@build()

		return true

	# rendering

	renderStylus: (fileDir) ->
		return false if not stylus.engine

		fileDir = @resolveDir fileDir

		if not fs.existsSync fileDir
			console.error lance.error 'Notice', 'templating renderStylus', 'File doesnt exist; ignoring'
			return false

		file = fs.readFileSync fileDir, 'utf8'

		if not file?
			console.error lance.error 'Warning', 'templating renderStylus', 'File not readable'
			return false

		dirname	= path.dirname fileDir

		engine = stylus.engine file
		engine.set 'paths', [ dirname ]
		engine.render (err, rendered) =>
			if err
				console.error lance.error 'Error', 'templating renderStylus stylus.render', err
				return false

			renderTo	= @resolveDir stylus.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext

			newFileDir	= path.join renderTo, name + '.css'

			fs.writeFile newFileDir, rendered

		return true

	renderCoffee: (fileDir) ->
		fileDir = @resolveDir fileDir

		if not fs.existsSync fileDir
			console.error lance.error 'Notice', 'templating renderCoffee', 'File doesnt exist; ignoring'

		file = fs.readFileSync fileDir, 'utf8'

		if not file?
			console.error lance.error 'Warning', 'templating renderCoffee', 'File not readable'

		rendered	= coffee.engine.compile file, coffee.options

		renderTo	= @resolveDir coffee.renderTo
		ext			= path.extname fileDir
		name		= path.basename fileDir, ext

		newFileDir	= path.join renderTo, name + '.js'

		fs.writeFile newFileDir, rendered

		return true

	renderEct: (dir, locals = {}, callback) ->
		if not ect.engine
			return callback 'Ect is not loaded'
		console.log dir
		ect.engine.render dir, locals, (err, rendered) ->
			if cfg.minify
				rendered = String.minify rendered

			callback err, rendered

		return true

	renderTemplate: (fileDir, locals = {}) ->
		return false if not template.engine

		fileDir = @resolveDir fileDir

		if not fileDir of @templates.compiled
			@compileTemplate fileDir, locals

		compiled = @templates.compiled[fileDir]
		rendered = compiled locals

		if cfg.minify
			rendered = String.minify rendered

		return rendered

	# compiling

	compileTemplate: (fileDir, locals = {}) ->
		return false if not template.engine

		fileDir = @resolveDir fileDir

		if not fileDir of @templates.files
			console.error lance.error 'Warning', 'templating compileTemplate', "[ #{fileDir} ] is not loaded, cannot be compiled"
			return false

		file = @templates.files[fileDir]

		compiled = template.engine.compile file, locals

		@templates.compiled[fileDir] = compiled

		return compiled

	# watching

	watchStylus: (fileDir) ->
		fs.watch fileDir, (event) =>
			return false if event isnt 'change'

			@renderStylus fileDir

		@watching.stylus[fileDir] = true

	watchCoffee: (fileDir) ->
		fs.watch fileDir, (event) =>
			return false if event isnt 'change'

			@renderCoffee fileDir

		@watching.coffee[fileDir] = true

	watchTemplates: (fileDir) ->
		fs.watch fileDir, (event) =>
			return false if event isnt 'change'

			@compileTemplate fileDir

		@watching.templates[fileDir] = true

	watch: ->
		{exploreDir, isExt}	= Function

		args	= [stylus.findIn, coffee.findIn, template.findIn]
		done	= []

		for arg in args
			continue if not arg

			if Function.type( arg ) is 'string'
				arg = [arg]

			for dir in arg

				dir = @resolveDir dir

				if dir in done
					continue

				done.push dir

				exploreDir dir, (file, fileDir, fileName, name, ext) =>
					if isExt ext, stylus.ext
						@watchStylus fileDir

					if isExt ext, coffee.ext
						@watchCoffee fileDir

					if isExt ext, template.ext
						@watchTemplates fileDir

			return true

	build: ->
		{exploreDir, isExt}	= Function

		args	= [stylus.findIn, coffee.findIn, template.findIn]

		for arg in args
			continue if not arg

			if Function.type( arg ) is 'string'
				arg = [arg]

			done	= []

			for dir in arg
				dir = @resolveDir dir

				if dir in done
					continue

				done.push dir

				exploreDir dir, (file, fileDir, fileName, name, ext) =>
					if isExt ext, stylus.ext
						@renderStylus fileDir

					if isExt ext, coffee.ext
						@renderCoffee fileDir

					if isExt ext, template.ext
						@templates.files[fileDir] = file
						@compileTemplate fileDir

		return true

}

# extend

lance.templating = templating

lanceExports.templating = {
	cfg				: templating.cfg
	locals			: {}
	init			: -> templating.init.apply templating, arguments

	render			: -> templating.renderEct.apply templating, arguments
	renderStylus	: -> templating.renderStylus.apply templating, arguments
	renderCoffee	: -> templating.renderCoffee.apply templating, arguments
	renderTemplate	: -> templating.render.apply templating, arguments
	compileTemplate	: -> templating.compileTemplate.apply templating, arguments

	build			: -> templating.build.apply templating, arguments
	watch			: -> templating.watch.apply templating, arguments
}
