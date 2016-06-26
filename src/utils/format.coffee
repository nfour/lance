typeOf = require 'lutils/typeOf'

module.exports = format =
	###
		Change a file extension
		
		@param filePath {String}
		@return {String}
	###
	fileExtension: (filePath, ext = '') ->
		return filePath if not filePath

		ext = ext.replace /^\./, ''
		ext = '.' + ext if ext

		return filePath.replace /\.[^\.]+$|$/, ext
		
	###
		Remove trailing, leading and duplicate whitespace
		
		@param str {String}
		@return {String}
	###
	minify: (str = '') ->
		str
			.replace /^\s+|\s+$/gm, ''
			.replace /\n/g, ''
			.replace /\s{2,}/g, ' '
			
	###
		Minifies CSS-like syntax
		
		@param str {String}
		@return {String}
	###
	minifyCss: (str = '') ->
		str
			.replace /^\s+|\s+$/gm, ''
			.replace ///
					\n
				|	\s+(?=\{)
				|	\s*\;\s*(?=\})
			///g, ''
			.replace /\s{2,}/g, ' '
			.replace /\s*\:\s+/g, ':'
			.replace /\{\s+/g, '{'
			.replace /\s+\}/g, '}'
			
	###
		Format a string to be a url-friendly slug

		@param str {String} This "is" some text!
		@return {String} str this-is-some-text
	###
	slugify: (str = '') ->
		( decodeURIComponent str.toString 'utf8' )
			.toLowerCase()
			.replace /[^a-z0-9-]+/g, '-'
			.replace /^[\s\-]+|[\s\-]+$/g, ''
			
	###
		Format a space or hyphen delimited string to camelCase

		@param str {String} some words here
		@return {String} someWordsHere
	###
	camelCase: (str) ->
		( format.slugify str )
			.replace /([^a-z0-9]+)([a-z0-9])/ig, (a, b, c) -> c.toUpperCase()
			.replace /([0-9]+)([a-zA-Z])/g, (a, b, c) -> c.toUpperCase()
			.replace /([0-9]+)([a-zA-Z])/g, (a, b, c) -> b + c.toUpperCase()

	###
		Iterates over an Object or Array
		calling JSON.stringify on any child Object or Arrays.
		Not recursive.
		
		@param obj {mixed}
		@param jsonArgs... Passed to JSON.stringify
		@return obj
	###
	jsonify: (obj, jsonArgs...) ->
		for key, val of obj
			switch typeOf val
				when 'object', 'array'
					obj[key] = JSON.stringify val, jsonArgs...

		return obj
	
	###
		Escapes all regexp characters in a string.
		
		@param str {String}
		@return str
	###
	escapeRegExp: (str) ->
		str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"
		
	isAbsolutePath: (filePath) ->
		console.log 'DEPRECATED:'.yellow, 'lance.format.isAbsolutePath'
		console.log "Use require('path').isAbsolute() instead"
		/^(\/|\w:)/.test filePath