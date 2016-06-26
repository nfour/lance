path		= require 'path'
{ minify }	= require './format'

lastError = 0

###
	Prettifies error messages for the console.
	
	@param err {Error or String} The error to parse
	@param scope {String} A supplimentary context note
	@param reverse {Boolean} Whether to reverse the ordering
	@return {String}
###
module.exports = (err, scope, reverse) ->
	if err not instanceof Error
		err = new Error err

	originalMessage	= err.message.split('\n')[0].toString()
	message			= originalMessage.replace /[-\/\\^$*+?.()|[\]{}]/g, "\\$&"
	regex			= new RegExp "#{ message }", 'i'

	lines = ( err?.stack or err or '' ).toString().split '\n'

	stack		= []
	grayStack	= []
	count = 0

	for line in lines[1..]
		line = line.replace /\t/g, '    '

		[ all, variable, variableExtra, file ] = []

		if m = line.match ///
			^ \s*
			at \s*
			([^\(]+)
			\s* \( ([^\)]+) \)
		///i
			[ all, variable, file ] = m

			if variableExtra = variable.match( /\s*\[(as[^\]]+)\]/i )?[1] or ''
				variable = variable.replace "[#{variableExtra}]", ''

			variable = minify variable

		else if m = line.match ///
			^ \s*
			at \s*
			(\S+)
			\s* $
		///
			[ all, file ] = m

		if file = minify file
			if file.match ///
				^ /.+/node_modules/bluebird
			|	^ native
			|	^ (node|module).js:
			///i
				continue

			if m = file.toString().match /([^:]+):(\d+):(\d+)/
				filePath	= m[1]
				lineNo		= m[2]
				charPos		= m[3]

				dirname		= path.dirname( filePath ) + '/'
				basename	= path.basename filePath

				str = if variable
					" #{lineNo.bold}\t #{charPos}\t#{variable}#{ if variableExtra then ' ' + variableExtra.grey else '' }\n\t"
				else
					" #{lineNo.bold}\t #{charPos}"

				stack.push str + "\t#{dirname.grey}#{basename.cyan}\n"
			else
				str = if variable
					" \t\t#{variable}#{ if variableExtra then ' ' + variableExtra.grey else '' }\n"
				else ''

				stack.push str + " \t\t#{file.cyan}\n"
		else
			continue if count > 500
			grayStack.push ' ' + line.grey
			++count

	stack.reverse() if reverse isnt false

	stack = stack.concat grayStack
	
	now = new Date()
	stack.push " + #{ now - lastError } ms".gray
	lastError = now
	
	stack.push ' ' + lines[0].red.bold + '\n'

	#if scope
	#	stack.push " #{ 'Context:'.red.bold } #{ scope.grey }" + '\n'

	stack.unshift ''
	return stack.join '\n'

module.exports.reverse = (err, scope) ->
	return module.exports err, scope, false