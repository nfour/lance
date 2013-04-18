
path		= require 'path'
fs			= require 'fs'
cluster		= require 'cluster'
lance		= require './lance'
uglifyJs	= require 'uglify-js'

{clone, merge, typeOf, isAbsolute, changeExt, isExt, exploreDir, empty, minify, minifyCss} = lance.utils

cfg		=
stylus	=
coffee	=
ect		=
css		=
js		= undefined

tpl					=
lance.tpl			=
lance.templating	= (newCfg = {}) ->
	cfg = merge clone( lance.cfg.templating ), newCfg

	cfg.root = cfg.root or lance.rootDir

	{stylus, coffee, ect, css, js} = cfg
	
	if coffee.engine isnt false
		coffee.engine = coffee.engine or require 'coffee-script'

	if stylus.engine isnt false
		try stylus.engine = stylus.engine or require 'stylus'

	if ect.engine isnt false
		try ect.engine = ect.engine	or require 'ect'

	# initialize ect if it hasnt been
	if ect.engine
		if typeOf( ect.engine ) is 'function'
			if ect.findIn and typeof ect.findIn is 'string'
				ect.options.root = path.join cfg.root, ect.findIn
			else
				ect.options.root = ect.options.root or cfg.root

			ect.options.ext	= ect.options.ext or ect.ext
			ect.engine		= ect.engine ect.options

		ect.ext = ect.ext or ect.options.ext or ''
	
	if css.inherit
		css.findIn = css.findIn or stylus.findIn
		css.renderTo = css.renderTo or stylus.renderTo

	if js.inherit
		js.findIn = js.findIn or coffee.findIn
		js.renderTo = js.renderTo or coffee.renderTo

	if stylus.inherit
		stylus.findIn = stylus.findIn or css.findIn
		stylus.renderTo = stylus.renderTo or css.renderTo

	if coffee.inherit
		coffee.findIn = coffee.findIn or js.findIn
		coffee.renderTo = coffee.renderTo or js.renderTo

	if cluster.isMaster
		if js.findIn
			if js.watch
				tpl.find.js.renderThenWatch()
			else
				tpl.find.js.render()

		if coffee.engine
			if coffee.watch
				tpl.find.coffee.renderThenWatch()
			else
				tpl.find.coffee.render()
		
		if css.findIn
			if css.watch
				tpl.find.css.renderThenWatch()
			else
				tpl.find.css.render()

		if stylus.engine
			if stylus.watch
				tpl.find.stylus.renderThenWatch()
			else
				tpl.find.stylus.render()

	return lance.templating

tpl.locals = {}

tpl.render = -> tpl.render.ect.apply tpl.render, arguments

tpl.render.ect = (dir, locals = {}, done = ->) ->
	if not ect.engine
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

tpl.render.toCss = (fileDir, done = ->) ->
	fileDir = resolveDir fileDir

	if isExt fileDir, stylus.ext
		@stylus fileDir, done

	else if isExt fileDir, css.ext
		@css fileDir, done

	else
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.toCss'
			error	: new Error "#{fileDir} matched no file extension, not rendering"
		), ''

tpl.render.toJs = (fileDir, done = ->) ->
	fileDir = resolveDir fileDir

	if isExt fileDir, coffee.ext
		@coffee fileDir, done

	else if isExt fileDir, js.ext
		@js fileDir, done

	else
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.toJs'
			error	: new Error "#{fileDir} matched no file extension, not rendering"
		), ''

tpl.render.css = (fileDir, done = ->) ->
	if not fs.existsSync fileDir
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.css fs.existsSync'
			error	: new Error "#{fileDir} doesnt exist"
		), ''

	fs.readFile fileDir, 'utf8', (err, file) =>
		if err or not file?
			return done lance.error(
				type	: 'warning'
				scope	: 'lance.tpl.render.css fs.readFile'
				error	: new Error "#{fileDir} not readable"
			), ''

		renderTo	= resolveDir css.renderTo
		ext			= path.extname fileDir
		name		= path.basename fileDir, ext
		newFileDir	= path.join renderTo, name + css.ext

		if css.minify
			file = minifyCss file

		if not @css.merge.add fileDir, file
			fs.writeFile newFileDir, file, (err) =>
				if err
					return done lance.error(
						type	: 'warning'
						scope	: 'lance.tpl.render.css fs.writeFile'
						error	: err
					), rendered

				done null, file
		else
			@css.merge done

tpl.render.stylus = (fileDir, done = ->) ->
	if not stylus.engine
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.stylus'
			error	: new Error 'Stylus engine unavaliable'
		), ''

	if not fs.existsSync fileDir
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.stylus fs.existsSync'
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
			if not @css.merge.add fileDir, rendered
				fs.writeFile newFileDir, rendered, (err) =>
					if err
						return done lance.error(
							type	: 'warning'
							scope	: 'lance.tpl.render.stylus stylus.engine.render fs.writeFile'
							error	: err
						), rendered

					done null, rendered
			else
				@css.merge done

tpl.render.js = (fileDir, done = ->) ->
	if not fs.existsSync fileDir
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.js fs.existsSync'
			error	: new Error "#{fileDir} doesnt exist"
		), ''

	fs.readFile fileDir, 'utf8', (err, file) =>
		if err or not file?
			return done lance.error(
				type	: 'warning'
				scope	: 'lance.tpl.render.js fs.readFile'
				error	: new Error "#{fileDir} not readable"
			), ''

		renderTo	= resolveDir js.renderTo
		ext			= path.extname fileDir
		name		= path.basename fileDir, ext
		newFileDir	= path.join renderTo, name + js.ext

		if js.minify
			if result = uglifyJs.minify file, { fromString: true }
				file = result.code

		if not @js.merge.add fileDir, file
			fs.writeFile newFileDir, file, (err) =>
				if err
					return done lance.error(
						type	: 'warning'
						scope	: 'lance.tpl.render.js fs.writeFile'
						error	: err
					), file

				done null, file
		else
			@js.merge done

tpl.render.coffee = (fileDir, done = ->) ->
	fileDir = resolveDir fileDir

	if not fs.existsSync fileDir
		return done lance.error(
			type	: 'notice'
			scope	: 'lance.tpl.render.coffee fs.existsSync'
			error	: new Error "#{fileDir} doesnt exist"
		), ''

	fs.readFile fileDir, 'utf8', (err, file) =>
		if err or not file?
			return done lance.error(
				type	: 'warning'
				scope	: 'lance.tpl.render.coffee fs.readFile'
				error	: new Error "#{fileDir} not readable"
			), ''

		rendered = coffee.engine.compile file

		renderTo	= resolveDir coffee.renderTo
		ext			= path.extname fileDir
		name		= path.basename fileDir, ext
		newFileDir	= path.join renderTo, name + '.js'

		if coffee.minify
			if result = uglifyJs.minify rendered, { fromString: true }
				rendered = result.code

		if not @js.merge.add fileDir, rendered
			fs.writeFile newFileDir, rendered, (err) =>
				if err
					return done lance.error(
						type	: 'warning'
						scope	: 'lance.tpl.render.coffee coffee.engine.render fs.writeFile'
						error	: err
					), rendered

				done null, rendered
		else
			@js.merge done

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

			merged += "/* #{path.basename fileDir} */\n#{rendered}\n\n"

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

	#console.log 'mergeCache', mergeCache

tpl.render.css.merge = (done = ->) ->
	tpl.render.merge @merge.cache, css.ext, done

tpl.render.js.merge = (done = ->) ->
	tpl.render.merge @merge.cache, js.ext, done

tpl.render.css.merge.cache = {}
tpl.render.js.merge.cache = {}

tpl.render.css.merge.add =
tpl.render.js.merge.add = (fileDir, str) ->
	return false if not fileDir or not str?

	# will group filenames like:
	# (app)-main.coffee, (app)-appendix.coffee		as app.coffee
	# 1-main.coffee, 1-appendix.coffee				as 1.coffee
	m = path.basename( fileDir ).match ///^
		( \d+ | \( [^\)]+ \) )
		[\-]
	///i

	if m?[1]
		group = m[1].replace /^\(|\)$/g, '' # trim surrounding round brackets

		if group not of @cache
			@cache[group] = {}

		@cache[group][fileDir] = str

		return true

	return false

# iterates over a directory and its subdirectories
# when it finds and matches (according to file extensions) then next is called
tpl.find = (findIn, findExt, next = ->) ->
	return false if not findIn or not findExt

	if typeof findIn is 'string'
		findIn = [findIn]

	if typeof findExt is 'string'
		findExt = [findExt]

	for dir in findIn
		dir = resolveDir dir

		exploreDir dir, (file, fileDir, fileName, name, fileExt = '') => # NOTE: add err to args
			for ext in findExt
				break if matched = isExt fileExt, ext

			if matched
				next file, fileDir, fileName, name, fileExt

# CSS #
tpl.find.css = (findIn, next = ->) ->
	findIn = findIn or css.findIn
	tpl.find findIn, css.ext, next

tpl.find.css.watch = (findIn = '') ->
	tpl.find.css findIn, (file, fileDir) =>
		tpl.watch fileDir

tpl.find.css.render = (findIn = '') ->
	tpl.find.css findIn, (file, fileDir) =>
		tpl.render.toCss fileDir

tpl.find.css.renderThenWatch = (findIn = '') ->
	tpl.find.css findIn, (file, fileDir) =>
		tpl.render.toCss fileDir
		tpl.watch fileDir

# STYLUS #
tpl.find.stylus = (findIn, next = ->) ->
	return false if not stylus.engine

	findIn = findIn or stylus.findIn
	tpl.find findIn, stylus.ext, next

tpl.find.stylus.watch = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.watch fileDir

tpl.find.stylus.render = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.render.stylus fileDir

tpl.find.stylus.renderThenWatch = (findIn = '') ->
	tpl.find.stylus findIn, (file, fileDir) =>
		tpl.render.stylus fileDir
		tpl.watch fileDir

# JS #
tpl.find.js = (findIn, next = ->) ->
	findIn = findIn or js.findIn
	tpl.find findIn, js.ext, next

tpl.find.js.watch = (findIn = '') ->
	tpl.find.js findIn, (file, fileDir) =>
		tpl.watch fileDir

tpl.find.js.render = (findIn = '') ->
	tpl.find.js findIn, (file, fileDir) =>
		tpl.render.toJs fileDir

tpl.find.js.renderThenWatch = (findIn = '') ->
	tpl.find.js findIn, (file, fileDir) =>
		tpl.render.toJs fileDir
		tpl.watch fileDir

# COFFEE #
tpl.find.coffee = (findIn, next = ->) ->
	findIn = findIn or coffee.findIn
	tpl.find findIn, coffee.ext, next

tpl.find.coffee.watch = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.watch fileDir

tpl.find.coffee.render = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.render.coffee fileDir

tpl.find.coffee.renderThenWatch = (findIn = '') ->
	tpl.find.coffee findIn, (file, fileDir) =>
		tpl.render.coffee fileDir
		tpl.watch fileDir

# NOTE: put these into a single function after they're proven to work to test
# if the closure will retain pointers to the correct objects, thus remaining DRY
tpl.watch = (fileDir) ->
	return false if not fileDir

	if ( isStylus = isExt( fileDir, stylus.ext ) ) or isExt( fileDir, css.ext )
		{watching, renderedAt} = tpl.watch.toCss
		render = if isStylus then tpl.render.stylus else tpl.render.toCss

	else if ( isCoffee = isExt( fileDir, coffee.ext ) ) or isExt( fileDir, js.ext )
		{watching, renderedAt} = tpl.watch.toJs
		render = if isCoffee then tpl.render.coffee else tpl.render.toJs

	else
		return false

	if fileDir of watching
		return false

	fs.watch fileDir, (event, filename) =>
		return false if event isnt 'change'

		now		= new Date().getTime()
		diff	= now - 500

		if fileDir of renderedAt and renderedAt[fileDir] > diff
			return false

		# has to be a timeout because fs.watch goes off twice, and the file
		# can be saved to in multiple parts, calling event change many times
		setTimeout (-> render.apply tpl.render, [fileDir]), 450

		renderedAt[fileDir] = new Date().getTime()

	watching[fileDir] = true

tpl.watch.toCss = {
	watching	: {}		# { fileDir: true } to know whether fileDir is already being watched
	renderedAt	: {}		# { fileDir: new Date().getTime() } for limiting re-rendering frequency
}

tpl.watch.toJs = {
	watching	: {}
	renderedAt	: {}
}

resolveDir = (dir = '', root = '') ->
	if isAbsolute dir
		return dir
	else
		return path.join root or cfg.root, dir
