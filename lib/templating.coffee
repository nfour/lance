
path	= require 'path'
fs		= require 'fs'
cluster	= require 'cluster'
lance	= require './lance'

{clone, merge} = Object
{type, isAbsolute, changeExt, isExt, exploreDir, empty} = Function
{minify, minifyCss, minifyJs} = String

cfg		=
stylus	=
coffee	=
ect		= undefined

tpl					=
lance.tpl			=
lance.templating	= (newCfg = {}) ->
	cfg = merge clone( lance.cfg.templating ), newCfg

	cfg.root = cfg.root or lance.rootDir

	stylus		= cfg.stylus
	coffee		= cfg.coffee
	ect			= cfg.ect
	
	coffee.engine = coffee.engine or require 'coffee-script'

	try stylus.engine	= stylus.engine	or require 'stylus'
	try ect.engine		= ect.engine	or require 'ect'

	stylus	= false if not stylus.engine
	ect		= false if not ect.engine

	# initialize ect if it hasnt been
	if ect
		if type( ect.engine ) is 'function'
			if ect.findIn
				ect.options.root = path.join cfg.root, ect.findIn
			else
				ect.options.root = ect.options.root or cfg.root

			ect.options.ext	= ect.options.ext or ect.ext
			ect.engine		= ect.engine ect.options

		ect.ext = ect.ext or ect.options.ext or ''

	if cluster.isMaster
		if coffee
			tpl.find.coffee.renderThenWatch()

		if stylus
			tpl.find.stylus.renderThenWatch()

	return lance.templating

tpl.locals = {}

# tpl.render

tpl.render = -> tpl.render.ect.apply tpl.render, arguments

tpl.render.ect = (dir, locals = {}, done = ->) ->
	if not ect
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.ect'
			error	: new Error 'ECT engine unavaliable'
		), ''

	ect.engine.render dir, locals, (err, rendered = '') ->
		if err
			return done lance.error(
				type	: 'notice'
				scope	: 'lance.tpl.render.ect'
				error	: err
			), rendered

		if ect.minify and rendered
			rendered = minify rendered

		done null, rendered

tpl.render.stylus = (fileDir, done = ->) ->
	if not stylus
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.stylus'
			error	: new Error 'Stylus engine unavaliable'
		), ''

	fileDir = resolveDir fileDir

	fs.exists fileDir, (exists) =>
		if not exists
			return done lance.error(
				type	: 'notice'
				scope	: 'lance.tpl.render.stylus fs.exists'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done lance.error(
					type	: 'warning'
					scope	: 'lance.tpl.render.stylus fs.readFile'
					error	: new Error "#{fileDir} not readable"
				), ''

			engine = stylus.engine file
			engine.set 'paths', [ path.dirname fileDir ]
			engine.render (err, rendered = '') =>
				if err
					return done lance.error(
						type	: 'warning'
						scope	: 'lance.tpl.render.stylus stylus.engine.render'
						error	: err
					), rendered

				if not rendered
					return done null, ''

				renderTo	= resolveDir stylus.renderTo
				ext			= path.extname fileDir
				name		= path.basename fileDir, ext

				newFileDir	= path.join renderTo, name + '.css'

				if stylus.minify
					rendered = minifyCss rendered

				# if it cant be added as a merge group then it will just try to write it alone
				if not @stylus.merge.add fileDir, rendered
					fs.writeFile newFileDir, rendered, (err) =>
						if err
							return done lance.error(
								type	: 'warning'
								scope	: 'lance.tpl.render.stylus stylus.engine.render fs.writeFile'
								error	: err
							), rendered

						done null, rendered
				else
					@stylus.merge done

tpl.render.coffee = (fileDir, done = ->) ->
	fileDir = resolveDir fileDir

	fs.exists fileDir, (exists) =>
		if not exists
			return done lance.error(
				type	: 'notice'
				scope	: 'lance.tpl.render.coffee fs.exists'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done lance.error(
					type	: 'warning'
					scope	: 'lance.tpl.render.coffee fs.readFile'
					error	: new Error "#{fileDir} not readable"
				)

			rendered	= coffee.engine.compile file

			if not rendered
				return done null, ''

			renderTo	= resolveDir coffee.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext
			newFileDir	= path.join renderTo, name + '.js'

			if coffee.minify
				rendered = minifyJs rendered

			if not @coffee.merge.add fileDir, rendered
				fs.writeFile newFileDir, rendered, (err) =>
					if err
						return done lance.error(
							type	: 'warning'
							scope	: 'lance.tpl.render.coffee coffee.engine.render fs.writeFile'
							error	: err
						), rendered

					done null, rendered
			else
				@coffee.merge done

# tpl.render.merge

# not called on its own. instead, tpl.render.[coffee|stylus].merge
# supplies it with mergeCache and a file extension
tpl.render.merge = (mergeCache, ext, done = ->) ->
	if empty mergeCache
		return done null, ''

	for groupName, group of mergeCache
		merged	= ''
		keys	= Object.keys( group ).sort()

		continue if not keys.length

		for fileDir in keys
			rendered = group[fileDir]

			merged += "\n/* #{path.basename fileDir} */\n#{rendered}\n"

		renderTo	= resolveDir coffee.renderTo

		newFileDir	= path.join renderTo, "#{groupName + ext}"

		fs.writeFile newFileDir, merged, (err) ->
			if err
				return done lance.error {
					type	: 'warning'
					scope	: 'lance.tpl.render.merge fs.writeFile'
					error	: err
				}, merged

			done null, merged

tpl.render.stylus.merge = (done = ->) ->
	tpl.render.merge @merge.cache, '.css', done

tpl.render.coffee.merge = (done = ->) ->
	tpl.render.merge @merge.cache, '.js', done

tpl.render.stylus.merge.cache = {}
tpl.render.coffee.merge.cache = {}

tpl.render.stylus.merge.add =
tpl.render.coffee.merge.add = (fileDir, rendered) ->
	return false if not fileDir or not rendered?

	# will group filenames like:
	# (app)-main.coffee, (app)-appendix.coffee		as app.coffee
	# 1-main.coffee, 1-appendix.coffee				as 1.coffee
	m = path.basename( fileDir ).match ///
		^
		( \d+ | \( [^\)]+ \) )
		[\-]
	///i

	if m?[1]
		console.log 'we gon replace r we?'
		group = m[1].replace /^\(|\)$/g, '' # trim surrounding round brackets

		if group not of @cache
			@cache[group] = {}

		@cache[group][fileDir] = rendered

		return true

	return false

# iterates over a directory and its subdirectories
# when it finds and matches (according to file extensions) then next is called
tpl.find = (findIn, findExt, next = ->) ->
	return false if not findIn or not findExt

	if type( findIn ) is 'string'
		findIn = [findIn]

	for dir in findIn
		dir = resolveDir dir

		exploreDir dir, (file, fileDir, fileName, name, ext = '') => # NOTE: add err to args
			matched = isExt ext, findExt

			if matched
				next file, fileDir, fileName, name, ext = ''

# calls the callback next whenever it finds a matching file
tpl.find.stylus = (findIn, next = ->) ->
	return false if not stylus

	findIn = findIn or stylus.findIn
	tpl.find findIn, stylus.ext, next

# when something is found, watch the fileDir
tpl.find.stylus.watch = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.watch.stylus fileDir

# when something is found, render the fileDir
tpl.find.stylus.render = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.render.stylus fileDir

# do both in proper order
tpl.find.stylus.renderThenWatch = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.render.stylus fileDir
		tpl.watch.stylus fileDir

tpl.find.coffee = (findIn, next = ->) ->
	return false if not coffee

	findIn = findIn or coffee.findIn
	tpl.find findIn, coffee.ext, next

tpl.find.coffee.watch = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.watch.coffee fileDir

tpl.find.coffee.render = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.render.coffee fileDir

tpl.find.coffee.renderThenWatch = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.render.coffee fileDir
		tpl.watch.coffee fileDir

# NOTE: put these into a single function after they're proven to work to test
# if the closure will retain pointers to the correct objects, thus remaining DRY
tpl.watch = {
	stylus: (fileDir = '') ->
		return false if not stylus

		{watching, renderedAt} = @stylus

		if watching[fileDir]
			return false

		fs.watch fileDir, (event) =>
			return false if event isnt 'change'
			now		= new Date().getTime()
			diff	= now - 1000

			if fileDir of renderedAt and renderedAt[fileDir] > diff
				return false

			tpl.render.stylus fileDir

			renderedAt[fileDir] = new Date().getTime()

		watching[fileDir] = true

	coffee: (fileDir = '') ->
		return false if not coffee

		{watching, renderedAt} = @coffee
		
		if watching[fileDir]
			return false

		fs.watch fileDir, (event) =>
			return false if event isnt 'change'
			now		= new Date().getTime()
			diff	= now - 1000

			if fileDir of renderedAt and renderedAt[fileDir] > diff
				return false
			
			tpl.render.stylus fileDir

			renderedAt[fileDir] = new Date().getTime()

		watching[fileDir] = true

}

tpl.watch.stylus.watching = {}		# { fileDir: true } to know whether fileDir is already being watched
tpl.watch.stylus.renderedAt = {}	# { fileDir: ms } for limiting re-rendering frequency
tpl.watch.coffee.watching = {}
tpl.watch.coffee.renderedAt = {}

resolveDir = (dir = '', root = '') ->
	if isAbsolute dir
		return dir
	else
		return path.join root or cfg.root, dir

### unused atm

	renderTemplate: (fileDir, locals = {}, callback) ->
		if not template.engine then callback 'Template engine invalid', null

		fileDir = resolveDir fileDir

		if not fileDir of tpl.templates.compiled
			tpl.compileTemplate fileDir, locals

		compiled = tpl.templates.compiled[fileDir]
		rendered = compiled locals

		if template.minify then rendered = String.minify rendered

		callback null, rendered

	compileTemplate: (fileDir, locals = {}) ->
		return false if not template.engine

		fileDir = resolveDir fileDir

		if not fileDir of tpl.templates.files
			return lance.error 'Warning', 'templating.compileTemplate', "'#{fileDir}' is not loaded"

		file = tpl.templates.files[fileDir]

		compiled = template.engine.compile file, locals

		tpl.templates.compiled[fileDir] = compiled

		return compiled

	watchTemplates: (fileDir) ->
		if not tpl.watching.templates[fileDir]
			fs.watch fileDir, (event) =>
				return false if event isnt 'change'

				tpl.compileTemplate fileDir

				tpl.watching.templates[fileDir] = true

	build: (doWatch = false, doBuild = true) ->
		args = [stylus.findIn, coffee.findIn, template.findIn]

		if doBuild then tpl.mergeCache = clone defaultMergeCache # cleans the mergeCache out

		for arg in args
			continue if not arg

			if type( arg ) is 'string' then arg = [arg]

			done = []

			for dir in arg
				dir = resolveDir dir

				if dir in done
					continue

				done.push dir

				exploreDir dir, (file, fileDir, fileName, name, ext) =>
					if isExt ext, stylus.ext
						tpl.renderStylus fileDir		if doBuild
						tpl.watchStylus fileDir		if doWatch

					if isExt ext, coffee.ext
						tpl.renderCoffee fileDir		if doBuild
						tpl.watchCoffee fileDir		if doWatch

					if isExt ext, template.ext
						tpl.templates.files[fileDir] = file

						tpl.compileTemplate fileDir	if doBuild
						tpl.watchTemplates fileDir		if doWatch

		return true

###