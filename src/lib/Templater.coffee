Promise			= require 'bluebird'
path			= require 'path'
fs				= Promise.promisifyAll require 'fs'
cluster			= require 'cluster'
mkdirp			= Promise.promisify require 'mkdirp'
watch			= require 'watch'

{ clone, merge, typeOf, format, coroutiner, exploreDir } = require '../utils'

module.exports = Templater = ->
	@constructor = (newCfg, @lance) =>
		oldCfg = require('../config').templater

		@cfg = clone.json oldCfg

		merge @cfg, newCfg if newCfg

		@cfg.root = @cfg.root or @lance.paths.root

		@locals = @cfg.locals

		@cfg.bundles = @cfg.bundles or @cfg.bundle

		{ stylus, coffee, templater, css, js, assets } = @cfg
		models = { stylus, coffee, templater, css, js, assets }

		if css.inherit
			css.findIn or css.findIn = stylus.findIn
			css.saveTo or css.saveTo = stylus.saveTo

		if js.inherit
			js.findIn or js.findIn = coffee.findIn
			js.saveTo or js.saveTo = coffee.saveTo

		if stylus.inherit
			stylus.findIn or stylus.findIn = css.findIn
			stylus.saveTo or stylus.saveTo = css.saveTo

		if coffee.inherit
			coffee.findIn or coffee.findIn = js.findIn
			coffee.saveTo or coffee.saveTo = js.saveTo

		try coffee.engine	= coffee.engine or require 'coffee-script'
		try stylus.engine	= stylus.engine or require 'stylus'
		try @Browserify		= require 'browserify'
		try @CoffeeReactify	= require 'coffee-reactify'
		try @Coffeeify		= require 'coffeeify'
		try @UglifyJs		= require 'uglify-js'
		
		css.match		= css.ext if not css.match
		js.match		= js.ext if not js.match
		stylus.match	= stylus.ext if not stylus.match
		coffee.match	= coffee.ext if not coffee.match
		
		for key, model of models
			if match = model.match
				model.matchFn = if typeOf.String match
					(fileDir = '') => @file.checkExtension fileDir, match
				else if typeOf.RegExp match
					(fileDir = '') => match.test fileDir
				else if typeOf.Function match
					match

			delete model.render if not typeOf.Function model.render
			delete model.watch if not typeOf.Function model.watch
			
			if 'saveTo' of model and not model.saveTo?
				model.saveTo = @cfg.saveTo or ''
				
			if 'findIn' of model and not model.findIn?
				model.findIn = @cfg.findIn or ''

		#
		# Ensure a templater
		#
		
		# Try to use ECT if there is no @cfg.templater
		if not templater.engine?
			try Ect = require 'ect'

			if Ect?
				templater.options or= {}
				merge.black templater.options, templater.ect
				
				@templater.useEct templater, Ect
		else
			# Try properties so that one can `require 'jade'` for an engine
			engine = templater.engine?.renderFile or templater.engine.render or templater.engine
			
			# Intercept to ensure relative paths are sorted
			templater.engine = (relativePath, data, done) =>
				filePath = format.fileExtension relativePath, @templater.ext
				filePath = @file.resolve filePath, @templater.findIn

				engine filePath, data, done
			
		if not templater.engine
			throw new Error 'Invalid templating engine'


		# Merge the configs straight over the top of the models, @stylus etc.
		for key, model of models
			merge this[ key ], model, 1

		return this

	@initialize = =>
		await = [ @bundle() ]

		if @assets.findIn and @assets.saveTo
			await.push @assets.syncDirectory()

		return Promise.all await

	###
		Alias to `@templater.render`.
	###
	@render = (filePath, locals) =>
		return @templater.render filePath, locals

	###
		The templater, for templating files!
	###
	@templater =
		render: (filePath = '', locals) =>
			@lance.emit 'templater.render.template', filePath, locals

			if locals
				locals = merge.black locals, clone @locals, 6
			else
				locals = @locals

			rendered = yield new Promise (resolve, reject) =>
				@templater.engine filePath, locals, (err, rendered = '') =>
					return reject err if err
					resolve rendered

			if @templater.minify and rendered
				rendered = format.minify rendered

			return rendered

		useEct: (templater, Ect) =>
			if not templater.options.root
				templater.options.root = if templater.findIn
					@file.resolveToRoot templater.findIn
				else
					@cfg.root

			templater.options.ext	=
			templater.ext			= templater.ext or templater.options.ext or '.ect'
			
			engine				= Ect templater.options
			templater.engine	= engine.render
			
	@stylus =
		render: (fileDir, destination) =>
			fileDir = @file.resolve fileDir, @stylus.findIn

			@lance.emit 'templater.render.stylus', fileDir

			file = yield @file.read fileDir
		
			promise = new Promise (resolve, reject) =>
				if not @stylus.engine
					return reject new Error "Stylus is not installed"
				
				try
					engine = @stylus.engine file, @stylus.options

					engine.set 'paths', [ path.dirname fileDir ]
					engine.set 'filename', fileDir

					dependencies = engine.deps()
				catch err then return reject err

				engine.render (err, rendered = '') =>
					return reject err if err
					return resolve rendered if not rendered

					if @stylus.minify
						rendered = format.minifyCss rendered

					results = [ rendered, dependencies, engine ]

					if destination
						newFileDir = @file.createSaveToPath destination or fileDir, {
							ext		: @css.ext
							findIn	: @stylus.findIn
							saveTo	: @stylus.saveTo
						}

						if dependencies
							@stylus.watchDependencies dependencies, fileDir, =>
								try
									@stylus.render fileDir, destination
								catch err
									console.error err

						resolve @file.write( newFileDir, rendered ).return results
					else
						resolve results

			promise.catch (err) =>
				@lance.emit 'err', err

		watchDependencies: (dependencies, fileDir, callback) =>
			listeners = @stylus.listeners[ fileDir ] or []

			dependencies.push fileDir if fileDir not in dependencies

			for dep in dependencies when dep not in listeners
				listeners.push dep

				@watch.once dep
				@lance.on "templater.watch.change.#{dep}", callback

			return @stylus.listeners[ fileDir ] = listeners

		listeners: {}

	@coffee =
		render: (fileDir, destination) =>
			fileDir = @file.resolve fileDir, @coffee.findIn

			@lance.emit 'templater.render.coffee', fileDir

			file = yield @file.read fileDir
			
			if not @coffee.engine
				throw new Error 'CoffeeScript is not installed'

			rendered = @coffee.engine.compile file

			newFileDir = @file.createSaveToPath destination or fileDir, {
				ext: @js.ext
				findIn: @coffee.findIn
				saveTo: @coffee.saveTo
			}

			if @coffee.minify
				try 
					if result = @UglifyJs.minify rendered, { fromString: true, mangle: false }
						rendered = result.code

			@file.write newFileDir, rendered

	@js =
		render: (fileDir, destination) =>
			fileDir = @file.resolve fileDir, @js.findIn

			@lance.emit 'templater.render.js', fileDir

			rendered = yield @file.read fileDir

			newFileDir = @file.createSaveToPath destination or fileDir, @js

			if @js.minify
				try
					if result = @UglifyJs.minify rendered, { fromString: true, mangle: false }
						rendered = result.code

			@file.write newFileDir, rendered

	@css =
		render: (fileDir, destination) =>
			fileDir = @file.resolve fileDir, @css.findIn

			@lance.emit 'templater.render.css', fileDir

			file = yield @file.read fileDir

			newFileDir = @file.createSaveToPath destination or fileDir, @css

			if @css.minify
				file = format.minifyCss file

			@file.write newFileDir, file

	@assets =
		watching: {}
		render: (fileDir, destination) =>
			fileDir = @file.resolve fileDir, @assets.findIn

			@lance.emit 'templater.render.assets', fileDir

			if not ( yield @file.exists fileDir )
				throw new Error "#{fileDir} doesnt exist"

			newFileDir = @file.createSaveToPath destination or fileDir, @assets
			readStream = fs.createReadStream fileDir

			return @file.writeStream readStream, newFileDir

		syncDirectory: (root = @assets.findIn) =>
			root = @file.resolveToRoot root

			await	= []
			o		= {}

			if @assets.matchFn?
				o.filter = (file) =>
					return @assets.matchFn file

			monitorDirectory = (filePath) =>
				return null if @assets.watching[ filePath ]
				@assets.watching[ filePath ] = true

				watch.createMonitor filePath, o, (monitor) =>
					for dir, file of monitor.files
						if file.isFile()
							await.push @assets.render dir

					monitor.on 'created', (fileDir, stats) =>
						@lance.emit 'templater.watch.created', fileDir, stats
						@lance.emit "templater.watch.created.#{fileDir}", fileDir, stats

						if stats.isFile() and @assets.matchFn fileDir
							@assets.render fileDir
						else if stats.isDirectory()
							@assets.syncDirectory fileDir

					monitor.on 'changed', (fileDir) =>
						@lance.emit 'templater.watch.change', fileDir
						@lance.emit "templater.watch.change.#{fileDir}", fileDir

						@assets.render fileDir

					monitor.on 'removed', (fileDir) =>
						@lance.emit 'templater.watch.removed', fileDir
						@lance.emit "templater.watch.removed.#{fileDir}", fileDir

			monitorDirectory root
			
			yield exploreDir root, {
				depth		: @cfg.depth or 8
				directory	: monitorDirectory
			}

			return yield Promise.all await

	@assets.find = (findIn, next) =>
		findIn = findIn or @assets.findIn
		@find findIn, @assets.match, next

	@assets.find.watch = (findIn) =>
		@assets.find findIn, (file, fileDir) =>
			@watch.asset fileDir

	@assets.find.render = (findIn) =>
		await = []
		yield @assets.find findIn, (file, fileDir) =>
			await.push @assets.render fileDir

		return Promise.all await

	@assets.find.renderAndWatch = (findIn) =>
		await = []
		yield @assets.find findIn, (file, fileDir) =>
			await.push @assets.render fileDir
			@assets.watch fileDir

		return Promise.all await

	#
	# Bundling
	#

	@bundle = (arg) =>
		arg = @cfg.bundles if not arg?

		await = []
		switch typeOf arg
			when 'object'
				for destination, files of arg
					await.push @bundle.render files, destination
			when 'array'
				for cfg in arg then do (cfg) =>
					destination	= cfg.destination or cfg.saveTo or cfg.to
					files		= cfg.files or cfg.file or cfg.source or cfg.from

					await.push @bundle.render files, destination
			else
				await.push @bundle.render.apply this, arguments

		return Promise.all await

	###
		Checks the first file in the files parameter to determine to render it toJs or toCss.
	###
	@bundle.render = (files, destination) =>
		firstFile = if typeOf.Array files
			files[0]
		else
			files

		return if @file.isToJs firstFile
			yield @bundle.render.toJs.apply this, arguments
		else if @file.isToCss firstFile
			yield @bundle.render.toCss.apply this, arguments

	@bundle.watchDependencies = (dependencies, key, callback) =>
		listeners = @bundle.listeners[ key ] or []

		for dep in dependencies when dep not in listeners
			listeners.push dep

			@watch.once dep
			@lance.on "templater.watch.change.#{dep}", callback

		return @bundle.listeners[ key ] = listeners

	@bundle.listeners = {}

	###
		Bundles up js/coffee-script with browserify.

		@param destination {String}
		@param files {String} {Array} Either one fileDir as a string or many in an array
	###
	@bundle.render.toJs = (files, destination) =>
		args = arguments

		files = [ files ] if not typeOf.Array files

		for fileDir, index in files
			model			= @file.resolveModel fileDir
			files[index]	= @file.resolve fileDir, model.findIn

		if not @Browserify
			throw new Error 'Browserify is not installed'
		
		b = @Browserify files, @cfg.browserify

		b.on 'file', (fileDir) =>
			# TODO: consider whether "destination" needs to be absolute pathed eg. savepath
			@bundle.watchDependencies [ fileDir ], destination, =>
				try
					@bundle.render.toJs.apply this, args
				catch err
					@lance.emit 'err', err

		@lance.emit 'templater.bundle.render', destination

		switch
			when @CoffeeReactify
				b.transform @CoffeeReactify, { global: true }
			when @Coffeeify
				b.transform @Coffeeify, { global: true }

		
		readStream = b.bundle().on 'error', Promise.method (err) =>
			readStream.end?()

		saveTo = @file.createSaveToPath destination

		return yield @file.writeStream readStream, saveTo


	###
		Bundles up css/stylus. Only accepts ONE file as `source`

		@param destination {String}
		@param source {String}
	###
	@bundle.render.toCss = (fileDirs, destination) =>
		args = arguments

		@lance.emit 'templater.bundle.render', destination

		if inputIsArray = typeOf.Array fileDirs
			allDeps = []
			engines = []
			files	= []
			for fileDir, index in fileDirs
				model	= @file.resolveModel fileDir
				fileDir	= @file.resolve fileDir, model.findIn

				[ rendered, dependencies, engine ] = yield @stylus.render fileDir

				allDeps.push fileDir
				allDeps = allDeps.concat dependencies if dependencies

				engines.push engine

				files.push rendered

			rendered = files.join '\n'

			if destination
				newFileDir = @file.createSaveToPath destination or fileDir,
					ext		: @css.ext
					findIn	: @stylus.findIn
					saveTo	: @stylus.saveTo

				@bundle.watchDependencies allDeps, newFileDir, =>
					try
						@bundle.render.toCss.apply this, args
					catch err
						console.error err

				yield @file.write newFileDir, rendered

			return [ rendered, allDeps, engines ]
		else
			return yield @stylus.render fileDirs, destination

	#
	# Watch file operations
	#


	@watch = (fileDir, callback) =>
		return false if not fileDir

		@lance.emit 'templater.watch', fileDir

		fs.watch fileDir, (event) =>
			return false if event isnt 'change'

			if fileDir of @watch.timeouts
				clearTimeout @watch.timeouts[ fileDir ]

			@watch.timeouts[ fileDir ] = setTimeout =>
				@lance.emit 'templater.watch.change', fileDir, event
				@lance.emit "templater.watch.change.#{fileDir}", fileDir, event

				delete @watch.timeouts[ fileDir ]
				callback fileDir, event if callback
			, @cfg.watchTimeout


		return true

	@watch.timeouts = {}

	@watch.once = (fileDir, callback) =>
		if fileDir not of @watch.once.watching
			if @watch fileDir, callback
				@watch.once.watching[ fileDir ] = true

	@watch.once.watching = {}

	#
	# File operations
	#

	@file = {}

	@file.deferredWrite = (key, fileDir, file) =>
		return new Promise (resolve) =>
			if cache = @file.deferredWrite.timeouts[ key ]
				cache.resolve()
			else
				cache = @file.deferredWrite.timeouts[ key ] = {}
			
			cache.fulfill = =>
				@file.write fileDir, file

			cache.resolve = resolve

			@file.deferredWrite.refresh key

	@file.deferredWrite.timeouts = {}

	@file.deferredWrite.refresh = (key, time = @cfg.writeTimeout) =>
		if cache = @file.deferredWrite.timeouts[ key ]
			clearTimeout cache.timeout if cache.timeout

			cache.timeout = setTimeout =>
				cache.resolve @file.deferredWrite.timeouts[ key ].fulfill()
				delete @file.deferredWrite.timeouts[ key ]
			, time

	@file.resolve = (dir = '', root = '') =>
		if not root
			if model = @file.resolveModel dir
				root = model.findIn
		
		root = @file.resolveToRoot root or @cfg.root

		return if format.isAbsolutePath dir then dir else path.join root, dir

	@file.resolveToRoot = (dir) =>
		return if format.isAbsolutePath dir then dir else path.join @cfg.root, dir

	@file.resolveModel = (fileDir) =>
		return switch
			when @file.checkExtension fileDir, @coffee.ext then @coffee
			when @file.checkExtension fileDir, @js.ext then @js
			when @file.checkExtension fileDir, @stylus.ext then @stylus
			when @file.checkExtension fileDir, @css.ext then @css
			when @file.checkExtension fileDir, @templater.ext then @templater

	@file.read = (fileDir, encoding) =>
		if not ( yield @file.exists fileDir )
			throw new Error "#{fileDir} doesnt exist"

		encoding = 'utf8' if not encoding and encoding isnt false
		return fs.readFileAsync fileDir, encoding

	@file.write = (fileDir, file) =>

		yield @file.createDirectory fileDir

		result = yield fs.writeFileAsync fileDir, file
		@lance.emit 'templater.writeFile', fileDir

		return result

	@file.writeStream = (readStream, fileDir) =>
		yield @file.createDirectory fileDir

		writeStream = fs.createWriteStream fileDir
		return new Promise (resolve, reject) =>
			errored = false
			error = (err) ->
				reject err if not errored
				errored = true

			readStream.once 'error', error
			writeStream.once 'error', error

			readStream.pipe writeStream
				.on 'error', error
				.on 'close', =>
					@lance.emit 'templater.writeFile', fileDir
					resolve()

	@file.createDirectory = (fileDir, done = ->) =>
		return new Promise (resolve, reject) =>
			mkdirp path.dirname( fileDir ), @cfg.writePermissions or ( 0o0755 & ( ~process.umask() ) ), (err) ->
				resolve()

	# By default, this preserve findIn rooted paths into the saveTo directory. Currently unchangable.
	@file.createSaveToPath = (fileDir, model) =>
		if not model
			model = @file.resolveModel fileDir

		{ findIn, saveTo, ext } = model

		findIn = findIn[0] if typeOf.Array findIn

		findIn	= @file.resolve findIn
		saveTo	= @file.resolve saveTo
		fileDir	= @file.resolve fileDir, findIn

		# todo: match the findIn array with the fileDir first?
		findIn = new RegExp ( '^' + format.escapeRegExp findIn )

		partial = if @cfg.preserveDirectory
			fileDir.replace findIn, ''
		else
			path.basename fileDir

		newFileDir = path.join saveTo, partial

		if ext
			newFileDir = format.fileExtension newFileDir, ext

		return newFileDir
	
	#
	# Check utils
	#
	
	@file.exists = (fileDir) => new Promise (resolve) -> fs.exists fileDir, resolve
	
	@file.checkExtension = (filePath, ext) =>
		return false if not filePath or typeof filePath isnt 'string' or not ext

		regex = if ext?
			ext = ext.replace /^\./, ''
			new RegExp ".#{ext}$", 'i'
		else
			/\.([^\.]+)$/

		return filePath?.match regex
	
	@file.isToJs = (fileDir) => @file.checkExtension( fileDir, @coffee.ext ) or @file.checkExtension( fileDir, @js.ext )
	@file.isToCss = (fileDir) => @file.checkExtension( fileDir, @stylus.ext ) or @file.checkExtension( fileDir, @css.ext )

	coroutiner.all this

	return @constructor.apply this, arguments

