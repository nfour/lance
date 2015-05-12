Promise	= require 'bluebird'
fs		= require 'fs'
path	= require 'path'

{ typeOf } = require './core'

module.exports = exploreDir = (dir, o, fileIterator) ->
	if typeOf.Function o
		fileIterator	= o
		o				= {}

	depth			= o.depth or 6
	ignorePrefix	= if o.ignorePrefix? then o.ignorePrefix else '_'

	iterator = Promise.coroutine (dir, depth) ->
		return null if --depth < 0
		
		filenames = yield fs.readdirAsync dir

		await = []

		for filename in filenames then do (filename) ->
			filePath = path.resolve path.join dir, filename

			await.push fs.statAsync( filePath ).then (stats) ->
				if filename[0] is ignorePrefix or not stats
					return null

				if stats.isDirectory()
					if o.directory
						o.directory filePath, stats

					return iterator filePath, depth

				else if stats.isFile() and o.file
					return fs.readFileAsync( filePath, 'utf8' ).then (file) ->
						ext		= path.extname filename
						name	= path.basename filename, ext

						o.file file, filePath, filename, name, ext

		yield return Promise.all await

	return iterator dir, depth