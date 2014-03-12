
path		= require 'path'
fs			= require 'fs'
cluster		= require 'cluster'
L			= require './lance'
uglifyJs	= require 'uglify-js'

{clone, merge, typeOf, isAbsolute, changeExt, isExt, changeExt, exploreDir, empty, minify, minifyCss, bind} = L.utils

defaultTpl = require('../cfg').tpl

module.exports = (newCfg) ->
	coffee = stylus = css = js = templater = self = undefined

	return new class
		constructor: ->
			self = this

			self.cfg = clone L.cfg.tpl
			# need to clone previous shit when we started lance to preserver << >>

			merge self.cfg, newCfg if newCfg

			self.cache = {
				toCss: {
					watching	: {} # { fileDir: true } to know whether fileDir is already being watched
					renderedAt	: {} # { fileDir: new Date().getTime() } for limiting re-rendering frequency
				}
				toJs: {
					watching	: {}
					renderedAt	: {}
				}
				merge: {
					js: {}
					css: {}
				}
				watchTimeouts: {}
			}

			self.cfg.rootDir = self.cfg.rootDir or L.rootDir

			self.locals = self.cfg.locals or {}

			{stylus, coffee, ect, css, js} = self.cfg

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
						ect.options.root = self.resolveDir ect.findIn
					else
						ect.options.root = ect.options.root or self.cfg.rootDir

					ect.options.ext		= ect.options.ext or ect.ext
					ect.engine			= ect.engine ect.options

				ect.ext = ect.ext or ect.options.ext or ''

			templater = ect
			
			if css.inherit
				css.findIn		= css.findIn or stylus.findIn
				css.renderTo	= css.renderTo or stylus.renderTo

			if js.inherit
				js.findIn		= js.findIn or coffee.findIn
				js.renderTo		= js.renderTo or coffee.renderTo

			if stylus.inherit
				stylus.findIn		= stylus.findIn or css.findIn
				stylus.renderTo	= stylus.renderTo or css.renderTo

			if coffee.inherit
				coffee.findIn	= coffee.findIn or js.findIn
				coffee.renderTo	= coffee.renderTo or js.renderTo

			#if cluster.isMaster # removed because naught wouldnt recompile shit
			if js.findIn
				if js.watch
					self.find.js.renderThenWatch()
				else
					self.find.js.render()

			if coffee.engine
				if coffee.watch
					self.find.coffee.renderThenWatch()
				else
					self.find.coffee.render()
			
			if css.findIn
				if css.watch
					self.find.css.renderThenWatch()
				else
					self.find.css.render()

			if stylus.engine
				if stylus.watch
					self.find.stylus.renderThenWatch()
				else
					self.find.stylus.render()

		# TODO: change this so that it works with consolodate.js instead of just going to ECT
		@::render = (dir, locals, done) ->
			if locals
				locals = merge.black locals, clone.merge( self.locals ), 6

			self.render.ect dir, locals, done

		@::render.ect = (dir = '', locals = self.locals, done = ->) ->
			if not templater.engine
				return done L.notice(
					'L.tpl.render.ect'
					new Error 'ECT engine unavaliable'
				), ''

			templater.engine.render dir, locals, (err, rendered = '') ->
				if err
					return done L.notice(
						'L.tpl.render.ect'
						err
					), rendered

				if templater.minify and rendered
					rendered = minify rendered

				done err, rendered

		@::render.toCss = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if isExt fileDir, stylus.ext
				self.render.stylus fileDir, done

			else if isExt fileDir, css.ext
				self.render.css fileDir, done

			else
				return done L.notice(
					'L.tpl.render.toCss'
					new Error "#{fileDir} matched no file extension, not rendering"
				), ''

		@::render.toJs = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if isExt fileDir, coffee.ext
				self.render.coffee fileDir, done

			else if isExt fileDir, js.ext
				self.render.js fileDir, done

			else
				return done L.notice(
					'L.tpl.render.toJs'
					new Error "#{fileDir} matched no file extension, not rendering"
				), ''

		@::render.css = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if not fs.existsSync fileDir
				return done L.notice(
					'L.tpl.render.css fs.existsSync'
					new Error "#{fileDir} doesnt exist"
				), ''

			fs.readFile fileDir, 'utf8', (err, file) =>
				if err or not file?
					return done L.notice(
						'L.tpl.render.css fs.readFile'
						new Error "#{fileDir} not readable"
					), ''

				renderTo	= self.resolveDir css.renderTo
				ext			= path.extname fileDir
				name		= path.basename fileDir, ext
				newFileDir	= path.join renderTo, name + css.ext

				if css.minify
					file = minifyCss file

				if not self.render.css.merge.add fileDir, file
					fs.writeFile newFileDir, file, (err) =>
						if err
							return done L.notice(
								'L.tpl.render.css fs.writeFile'
								err
							), rendered

						done null, file
				else
					self.render.css.merge done

		@::render.stylus = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if not stylus.engine
				return done L.notice(
					'L.tpl.render.stylus'
					new Error 'Stylus engine unavaliable'
				), ''

			if not fs.existsSync fileDir
				return done L.notice(
					'L.tpl.render.stylus fs.existsSync'
					new Error "#{fileDir} doesnt exist"
				), ''

			fs.readFile fileDir, 'utf8', (err, file) =>
				if err or not file?
					return done L.notice(
						'L.tpl.render.stylus fs.readFile'
						new Error "#{fileDir} not readable"
					), ''

				engine = stylus.engine file
				engine.set 'paths', [ path.dirname fileDir ]
				engine.render (err, rendered = '') =>
					if err
						return done L.notice(
							'L.tpl.render.stylus stylus.engine.render'
							err
						), rendered

					if not rendered
						return done null, ''

					renderTo	= self.resolveDir stylus.renderTo
					ext			= path.extname fileDir
					name		= path.basename fileDir, ext

					newFileDir	= path.join renderTo, name + '.css'

					if stylus.minify
						rendered = minifyCss rendered

					# if it cant be added as a merge group then it will just try to write it alone
					if not self.render.css.merge.add fileDir, rendered
						fs.writeFile newFileDir, rendered, (err) =>
							if err
								return done L.notice(
									'L.tpl.render.stylus stylus.engine.render fs.writeFile'
									err
								), rendered

							done null, rendered
					else
						self.render.css.merge done

		@::render.js = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if not fs.existsSync fileDir
				return done L.notice(
					'L.tpl.render.js fs.existsSync'
					new Error "#{fileDir} doesnt exist"
				), ''

			fs.readFile fileDir, 'utf8', (err, file) =>
				if err or not file?
					return done L.notice(
						'L.tpl.render.js fs.readFile'
						new Error "#{fileDir} not readable"
					), ''

				renderTo	= self.resolveDir js.renderTo
				ext			= path.extname fileDir
				name		= path.basename fileDir, ext
				newFileDir	= path.join renderTo, name + js.ext

				if js.minify
					try
						if result = uglifyJs.minify rendered, { fromString: true, mangle: false }
							rendered = result.code
					catch err
						done()

				if not self.render.js.merge.add fileDir, file
					fs.writeFile newFileDir, file, (err) =>
						if err
							return done L.notice(
								'L.tpl.render.js fs.writeFile'
								err
							), file

						done null, file
				else
					self.render.js.merge done

		@::render.coffee = (fileDir, done = ->) ->
			fileDir = self.resolveDir fileDir

			if not fs.existsSync fileDir
				return done L.notice(
					'L.tpl.render.coffee fs.existsSync'
					new Error "#{fileDir} doesnt exist"
				), ''

			fs.readFile fileDir, 'utf8', (err, file) =>
				if err or not file?
					return done L.notice(
						'L.tpl.render.coffee fs.readFile'
						new Error "#{fileDir} not readable"
					), ''

				try
					rendered = coffee.engine.compile file
				catch err
					return done L.notice(
						'L.tpl.render.coffee compile'
						err
					), ''

				renderTo	= self.resolveDir coffee.renderTo
				ext			= path.extname fileDir
				name		= path.basename fileDir, ext
				newFileDir	= path.join renderTo, name + '.js'

				if coffee.minify
					try
						if result = uglifyJs.minify rendered, { fromString: true, mangle: false }
							rendered = result.code
					catch err
						return done L.notice(
							'L.tpl.render.coffee uglifyJs'
							err
						), ''

				if not self.render.js.merge.add fileDir, rendered
					fs.writeFile newFileDir, rendered, (err) =>
						if err
							err = L.notice(
								'L.tpl.render.coffee coffee.engine.render fs.writeFile'
								err
							)

						done err, rendered
				else
					self.render.js.merge done

		# self.render.merge

		@::render.css.merge = (done = ->) ->
			self.render.merge self.cache.merge.css, css, done

		@::render.js.merge = (done = ->) ->
			self.render.merge self.cache.merge.js, js, done

		@::render.js.merge.add = (fileDir, str) ->
			self.render.merge.add 'js', fileDir, str

		@::render.css.merge.add = (fileDir, str) ->
			self.render.merge.add 'css', fileDir, str

		# not called on its own. instead, self.render.[coffee|stylus].merge
		# supplies it with mergeCache and a file extension
		@::render.merge = (mergeCache, modal, done = ->) ->
			{ext, renderTo, findIn} = modal
			findIn = [findIn] if not typeOf.Array findIn

			if empty mergeCache
				return done null, ''

			merged = ''

			if self.cfg.merge then for group in self.cfg.merge
				continue if group.name not of mergeCache

				for relPath in group.files
					for fileDir, rendered of mergeCache[group.name]
						parentDir = path.dirname fileDir

						for findInPath in findIn
							constructedDir = path.join findInPath or '', relPath

							if constructedDir is fileDir
								merged += "/* #{path.basename fileDir} */\n#{rendered}\n\n"

				renderTo	= self.resolveDir renderTo

				newFileDir	= path.join renderTo, changeExt group.name, ext

				fs.writeFile newFileDir, merged, (err) ->
					if err
						return done L.notice {
							'L.tpl.render.merge fs.writeFile'
							err
						}, merged

					done null, merged

		@::render.merge.add = (type, fileDir, str) ->
			return false if not fileDir or not str?
			findIn = self.cfg[type]?.findIn
			findIn = [findIn] if not typeOf.Array findIn

			parentDir = path.dirname fileDir

			if self.cfg.merge then for group in self.cfg.merge
				for relPath in group.files
					for findInPath in findIn
						constructedDir = path.join findInPath or '', relPath

						if constructedDir is fileDir
							cache = self.cache.merge[type]

							if group.name not of cache
								cache[group.name] = {}

							cache[group.name][fileDir] = str

							return true

			return false

		@::render.merge.addOld = (type, fileDir, str) ->
			return false if not fileDir or not str?

			# will group filenames like:
			# (app)-main.coffee, (app)-appendix.coffee		as app.coffee
			m = path.basename( fileDir ).match ///^
				\( \s* ( [^\)]+ ) \s* \)
				[\-]
			///i

			if group = m?[1]
				cache = self.cache.merge[type]

				if group not of cache
					cache[group] = {}

				cache[group][fileDir] = str

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
				dir = self.resolveDir dir

				exploreDir dir, (file, fileDir, fileName, name, fileExt = '') =>
					for ext in findExt
						break if matched = isExt fileExt, ext

					if matched
						next file, fileDir, fileName, name, fileExt

		# CSS #
		@::find.css = (findIn, next = ->) ->
			findIn = findIn or css.findIn
			self.find findIn, css.ext, next

		@::find.css.watch = (findIn = '') ->
			self.find.css findIn, (file, fileDir) =>
				self.watch fileDir

		@::find.css.render = (findIn = '') ->
			self.find.css findIn, (file, fileDir) =>
				self.render.toCss fileDir

		@::find.css.renderThenWatch = (findIn = '') ->
			self.find.css findIn, (file, fileDir) =>
				self.render.toCss fileDir
				self.watch fileDir

		# STYLUS #
		@::find.stylus = (findIn, next = ->) ->
			return false if not stylus.engine

			findIn = findIn or stylus.findIn
			self.find findIn, stylus.ext, next

		@::find.stylus.watch = (findIn = '') ->
			self.find.stylus findIn, (file, fileDir) =>
				self.watch fileDir

		@::find.stylus.render = (findIn = '') ->
			self.find.stylus findIn, (file, fileDir) =>
				self.render.stylus fileDir

		@::find.stylus.renderThenWatch = (findIn = '') ->
			self.find.stylus findIn, (file, fileDir) =>
				self.render.stylus fileDir
				self.watch fileDir

		# JS #
		@::find.js = (findIn, next = ->) ->
			findIn = findIn or js.findIn
			self.find findIn, js.ext, next

		@::find.js.watch = (findIn = '') ->
			self.find.js findIn, (file, fileDir) =>
				self.watch fileDir

		@::find.js.render = (findIn = '') ->
			self.find.js findIn, (file, fileDir) =>
				self.render.toJs fileDir

		@::find.js.renderThenWatch = (findIn = '') ->
			self.find.js findIn, (file, fileDir) =>
				self.render.toJs fileDir
				self.watch fileDir

		# COFFEE #
		@::find.coffee = (findIn, next = ->) ->
			findIn = findIn or coffee.findIn
			self.find findIn, coffee.ext, next

		@::find.coffee.watch = (findIn = '') ->
			self.find.coffee findIn, (file, fileDir) =>
				self.watch fileDir

		@::find.coffee.render = (findIn = '') ->
			self.find.coffee findIn, (file, fileDir) =>
				self.render.coffee fileDir

		@::find.coffee.renderThenWatch = (findIn = '') ->
			self.find.coffee findIn, (file, fileDir) =>
				self.render.coffee fileDir
				self.watch fileDir

		@::watch = (fileDir) ->
			return false if not fileDir

			if ( isStylus = isExt( fileDir, stylus.ext ) ) or isExt( fileDir, css.ext )
				{watching, renderedAt} = self.cache.toCss
				render = if isStylus then self.render.stylus else self.render.toCss

			else if ( isCoffee = isExt( fileDir, coffee.ext ) ) or isExt( fileDir, js.ext )
				{watching, renderedAt} = self.cache.toJs
				render = if isCoffee then self.render.coffee else self.render.toJs

			else
				return false

			if fileDir of watching
				return false

			fs.watch fileDir, (event) =>
				return false if event isnt 'change'

				watchTimeouts = self.cache.watchTimeouts

				if fileDir of watchTimeouts
					clearTimeout watchTimeouts[fileDir]
					delete watchTimeouts[fileDir]

				watchTimeouts[fileDir] = setTimeout ( ->
					render fileDir
				), self.cfg.watchTimeout

			watching[fileDir] = true

		@::resolveDir = (dir = '', root = '') ->
			return dir if typeof dir isnt 'string'
			
			if isAbsolute dir
				return dir
			else
				return path.join root or self.cfg.rootDir or '', dir
