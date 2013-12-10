
path		= require 'path'
fs			= require 'fs'
cluster		= require 'cluster'
L			= require './lance'
uglifyJs	= require 'uglify-js'

{clone, merge, typeOf, isAbsolute, changeExt, isExt, exploreDir, empty, minify, minifyCss, bind} = L.utils

###

class Chicken
  s= 1
  constructor: -> 
    s= tpl.
    tpl.niggers = 122
  @::pie = -> alert s.niggers
  @::pie.sex = ->
    alert s.niggers + 2
  tpl.change = -> chicken = 'no'

 use the above syntax for classes in future as it is the only way to keep everything "together"
 while also when new Class(), we get to remake everything new instead of the herp that Im doing right now
 mfw i just realized why people use classes. loooooooooOOOl

###

class Tpl
	coffee = stylus = css = js = templater =
	tpl	= undefined

	constructor: (newCfg) ->
		tpl = @

		tpl.cfg = clone L.cfg.tpl or L.cfg.templating
		merge tpl.cfg,  newCfg if newCfg

		tpl.cache = {
			toCss: {
				watching	: {} # { fileDir: true } to know whether fileDir is already being watched
				renderedAt	: {} # { fileDir: new Date().getTime() } for limiting re-rendering frequency
			}
			toJs: {
				watching	: {}
				renderedAt	: {}
			}
			merge: {}
		}

		tpl.cfg.rootDir = tpl.cfg.rootDir or L.rootDir

		tpl.locals = tpl.cfg.locals or {}

		{stylus, coffee, ect, css, js} = tpl.cfg

		if coffee.engine isnt false
			coffee.engine = coffee.engine or require 'coffee-script'

		if stylus.engine isnt false
			try stylus.engine = stylus.engine or require 'stylus'

		if ect.engine isnt false
			try ect.engine = ect.engine or require 'ect'

		# initialize ect if it hasnt been
		if ect.engine
			if typeOf.Function ect.engine
				if ect.findIn and typeOf.String ect.findIn
					ect.options.root = tpl.resolveDir ect.findIn
				else
					ect.options.root = ect.options.root or tpl.cfg.rootDir

				ect.options.ext	= ect.options.ext or ect.ext
				ect.engine			= ect.engine ect.options

			ect.ext = ect.ext or ect.options.ext or ''

		templater = ect
		
		if css.inherit
			css.findIn		= css.findIn or stylus.findIn
			css.renderTo	= css.renderTo or stylus.renderTo

		if js.inherit
			js.findIn		= js.findIn or coffee.findIn
			js.renderTo	= js.renderTo or coffee.renderTo

		if stylus.inherit
			stylus.findIn		= stylus.findIn or css.findIn
			stylus.renderTo	= stylus.renderTo or css.renderTo

		if coffee.inherit
			coffee.findIn		= coffee.findIn or js.findIn
			coffee.renderTo	= coffee.renderTo or js.renderTo

		#if cluster.isMaster # removed because naught wouldnt recompile shit
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

	# TODO: change this so that it works with consolodate.js instead of just going to ECT
	@::render = -> tpl.render.ect.apply tpl.render, arguments

	@::render.ect = (dir = '', locals = {}, done = ->) ->
		if not templater.engine
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.ect'
				error	: new Error 'ECT engine unavaliable'
			), ''

		try
			templater.engine.render dir, locals, (err, rendered = '') ->
				if err
					return done L.error(
						type	: 'notice'
						scope	: 'L.tpl.render.ect'
						error	: err
					), rendered

				if templater.minify and rendered
					rendered = minify rendered

				done err, rendered
		catch err
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.ect'
				error	: err
			)

	@::render.toCss = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if isExt fileDir, stylus.ext
			tpl.render.stylus fileDir, done

		else if isExt fileDir, css.ext
			tpl.render.css fileDir, done

		else
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.toCss'
				error	: new Error "#{fileDir} matched no file extension, not rendering"
			), ''

	@::render.toJs = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if isExt fileDir, coffee.ext
			tpl.render.coffee fileDir, done

		else if isExt fileDir, js.ext
			tpl.render.js fileDir, done

		else
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.toJs'
				error	: new Error "#{fileDir} matched no file extension, not rendering"
			), ''

	@::render.css = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if not fs.existsSync fileDir
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.css fs.existsSync'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done L.error(
					type	: 'warning'
					scope	: 'L.tpl.render.css fs.readFile'
					error	: new Error "#{fileDir} not readable"
				), ''

			renderTo	= tpl.resolveDir css.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext
			newFileDir	= path.join renderTo, name + css.ext

			if css.minify
				file = minifyCss file

			if not tpl.render.css.merge.add fileDir, file
				fs.writeFile newFileDir, file, (err) =>
					if err
						return done L.error(
							type	: 'warning'
							scope	: 'L.tpl.render.css fs.writeFile'
							error	: err
						), rendered

					done null, file
			else
				tpl.render.css.merge done

	@::render.stylus = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if not stylus.engine
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.stylus'
				error	: new Error 'Stylus engine unavaliable'
			), ''

		if not fs.existsSync fileDir
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.stylus fs.existsSync'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done L.error(
					type	: 'warning'
					scope	: 'L.tpl.render.stylus fs.readFile'
					error	: new Error "#{fileDir} not readable"
				), ''

			engine = stylus.engine file
			engine.set 'paths', [ path.dirname fileDir ]
			engine.render (err, rendered = '') =>
				if err
					return done L.error(
						type	: 'warning'
						scope	: 'L.tpl.render.stylus stylus.engine.render'
						error	: err
					), rendered

				if not rendered
					return done null, ''

				renderTo	= tpl.resolveDir stylus.renderTo
				ext			= path.extname fileDir
				name		= path.basename fileDir, ext

				newFileDir	= path.join renderTo, name + '.css'

				if stylus.minify
					rendered = minifyCss rendered

				# if it cant be added as a merge group then it will just try to write it alone
				if not tpl.render.css.merge.add fileDir, rendered
					fs.writeFile newFileDir, rendered, (err) =>
						if err
							return done L.error(
								type	: 'warning'
								scope	: 'L.tpl.render.stylus stylus.engine.render fs.writeFile'
								error	: err
							), rendered

						done null, rendered
				else
					tpl.render.css.merge done

	@::render.js = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if not fs.existsSync fileDir
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.js fs.existsSync'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done L.error(
					type	: 'warning'
					scope	: 'L.tpl.render.js fs.readFile'
					error	: new Error "#{fileDir} not readable"
				), ''

			renderTo	= tpl.resolveDir js.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext
			newFileDir	= path.join renderTo, name + js.ext

			if js.minify
				try
					if result = uglifyJs.minify rendered, { fromString: true, mangle: false }
						rendered = result.code
				catch err
					done()

			if not tpl.render.js.merge.add fileDir, file
				fs.writeFile newFileDir, file, (err) =>
					if err
						return done L.error(
							type	: 'warning'
							scope	: 'L.tpl.render.js fs.writeFile'
							error	: err
						), file

					done null, file
			else
				tpl.render.js.merge done

	@::render.coffee = (fileDir, done = ->) ->
		fileDir = tpl.resolveDir fileDir

		if not fs.existsSync fileDir
			return done L.error(
				type	: 'notice'
				scope	: 'L.tpl.render.coffee fs.existsSync'
				error	: new Error "#{fileDir} doesnt exist"
			), ''

		fs.readFile fileDir, 'utf8', (err, file) =>
			if err or not file?
				return done L.error(
					type	: 'warning'
					scope	: 'L.tpl.render.coffee fs.readFile'
					error	: new Error "#{fileDir} not readable"
				), ''

			try
				rendered = coffee.engine.compile file
			catch err
				return done()

			renderTo	= tpl.resolveDir coffee.renderTo
			ext			= path.extname fileDir
			name		= path.basename fileDir, ext
			newFileDir	= path.join renderTo, name + '.js'

			if coffee.minify
				try
					if result = uglifyJs.minify rendered, { fromString: true, mangle: false }
						rendered = result.code
				catch err
					return done()

			if not tpl.render.js.merge.add fileDir, rendered
				fs.writeFile newFileDir, rendered, (err) =>
					if err
						return done L.error(
							type	: 'warning'
							scope	: 'L.tpl.render.coffee coffee.engine.render fs.writeFile'
							error	: err
						), rendered

					done null, rendered
			else
				tpl.render.js.merge done

	# tpl.render.merge

	# not called on its own. instead, tpl.render.[coffee|stylus].merge
	# supplies it with mergeCache and a file extension
	@::render.merge = (mergeCache, ext, done = ->) ->
		if empty mergeCache
			return done null, ''

		for groupName, group of mergeCache
			merged	= ''
			keys	= Object.keys( group ).sort()

			continue if not keys.length

			for fileDir in keys
				rendered = group[fileDir]

				merged += "/* #{path.basename fileDir} */\n#{rendered}\n\n"

			renderTo	= tpl.resolveDir coffee.renderTo

			newFileDir	= path.join renderTo, "#{groupName + ext}"

			fs.writeFile newFileDir, merged, (err) ->
				if err
					return done L.error {
						type	: 'warning'
						scope	: 'L.tpl.render.merge fs.writeFile'
						error	: err
					}, merged

				done null, merged

	@::render.css.merge = (done = ->) ->
		tpl.render.merge tpl.cache.merge.css, css.ext, done

	@::render.js.merge = (done = ->) ->
		tpl.render.merge tpl.cache.merge.js, js.ext, done

	@::render.css.merge.cache = {}
	@::render.js.merge.cache = {}

	Tpl	::render.css.merge.add =
	Tpl	::render.js.merge.add = (fileDir, str) ->
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

			if group not of tpl.cache.merge
				tpl.cache.merge[group] = {}

			tpl.cache.merge[group][fileDir] = str

			return true

		return false

	# iterates over a directory and its subdirectories
	# when it finds and matches (according to file extensions) then next is called
	@::find = (findIn, findExt, next = ->) ->
		return false if not findIn or not findExt

		if typeof findIn is 'string'
			findIn = [findIn]

		if typeof findExt is 'string'
			findExt = [findExt]

		for dir in findIn
			dir = tpl.resolveDir dir

			exploreDir dir, (file, fileDir, fileName, name, fileExt = '') =>
				for ext in findExt
					break if matched = isExt fileExt, ext

				if matched
					next file, fileDir, fileName, name, fileExt

	# CSS #
	@::find.css = (findIn, next = ->) ->
		findIn = findIn or css.findIn
		tpl.find findIn, css.ext, next

	@::find.css.watch = (findIn = '') ->
		tpl.find.css findIn, (file, fileDir) =>
			tpl.watch fileDir

	@::find.css.render = (findIn = '') ->
		tpl.find.css findIn, (file, fileDir) =>
			tpl.render.toCss fileDir

	@::find.css.renderThenWatch = (findIn = '') ->
		tpl.find.css findIn, (file, fileDir) =>
			tpl.render.toCss fileDir
			tpl.watch fileDir

	# STYLUS #
	@::find.stylus = (findIn, next = ->) ->
		return false if not stylus.engine

		findIn = findIn or stylus.findIn
		tpl.find findIn, stylus.ext, next

	@::find.stylus.watch = (findIn = '') ->
		tpl.find.stylus findIn, (file, fileDir) =>
			tpl.watch fileDir

	@::find.stylus.render = (findIn = '') ->
		tpl.find.stylus findIn, (file, fileDir) =>
			tpl.render.stylus fileDir

	@::find.stylus.renderThenWatch = (findIn = '') ->
		tpl.find.stylus findIn, (file, fileDir) =>
			tpl.render.stylus fileDir
			tpl.watch fileDir

	# JS #
	@::find.js = (findIn, next = ->) ->
		findIn = findIn or js.findIn
		tpl.find findIn, js.ext, next

	@::find.js.watch = (findIn = '') ->
		tpl.find.js findIn, (file, fileDir) =>
			tpl.watch fileDir

	@::find.js.render = (findIn = '') ->
		tpl.find.js findIn, (file, fileDir) =>
			tpl.render.toJs fileDir

	@::find.js.renderThenWatch = (findIn = '') ->
		tpl.find.js findIn, (file, fileDir) =>
			tpl.render.toJs fileDir
			tpl.watch fileDir

	# COFFEE #
	@::find.coffee = (findIn, next = ->) ->
		findIn = findIn or coffee.findIn
		tpl.find findIn, coffee.ext, next

	@::find.coffee.watch = (findIn = '') ->
		tpl.find.coffee findIn, (file, fileDir) =>
			tpl.watch fileDir

	@::find.coffee.render = (findIn = '') ->
		tpl.find.coffee findIn, (file, fileDir) =>
			tpl.render.coffee fileDir

	@::find.coffee.renderThenWatch = (findIn = '') ->
		tpl.find.coffee findIn, (file, fileDir) =>
			tpl.render.coffee fileDir
			tpl.watch fileDir

	# NOTE: put these into a single function after they're proven to work to test
	# if the closure will retain pointers to the correct objects, thus remaining DRY
	@::watch = (fileDir) ->
		return false if not fileDir

		if ( isStylus = isExt( fileDir, stylus.ext ) ) or isExt( fileDir, css.ext )
			{watching, renderedAt} = tpl.cache.toCss
			render = if isStylus then tpl.render.stylus else tpl.render.toCss

		else if ( isCoffee = isExt( fileDir, coffee.ext ) ) or isExt( fileDir, js.ext )
			{watching, renderedAt} = tpl.cache.toJs
			render = if isCoffee then tpl.render.coffee else tpl.render.toJs

		else
			return false

		if fileDir of watching
			return false

		fs.watch fileDir, (event) =>
			return false if event isnt 'change'

			now		= new Date().getTime()
			diff	= now - tpl.cfg.watchInterval

			if fileDir of renderedAt and renderedAt[fileDir] > diff
				return false

			renderedAt[fileDir] = new Date().getTime()

			# has to be a timeout because fs.watch goes off twice, and the file
			# can be saved in multiple parts, calling event "change" too often

			setTimeout ( ->
				render fileDir
			), tpl.cfg.watchChangeWait

		watching[fileDir] = true

	@::resolveDir = (dir = '', root = '') ->
		return dir if typeof dir isnt 'string'
		
		if isAbsolute dir
			return dir
		else
			return path.join root or tpl.cfg.root or '', dir


module.exports = Tpl