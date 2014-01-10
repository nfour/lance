
L		= require './lance'
path	= require 'path'
fs		= require 'fs'

{clone, merge, typeOf} = L.utils

L.error = ->
	error = L.error.parse arguments

	# emitting 'error' results in said error being thrown
	L.emit 'err', error

	console.error error.text
	L.writeError error.text

	if error.severity is 'fatal'
		process.exit(0)

	return error

L.notice = ->
	error = L.error.parse arguments

	L.emit 'err', error

	console.error error.text
	L.writeError error.text

	return error

L.error.parse = (args) ->
	if typeOf.Object args[0]
		opt = args[0]
	else
		if args[0] instanceof Error
			opt = { error: args[0] }
		else
			opt = { type: args[0], error: args[1] }

	type	= opt.type or 'warning'
	scope	= opt.scope or ''
	error	= opt.error or 'Error'

	if error not instanceof Error
		error = new Error error

	msg = error.message or ''

	for fatalType in [EvalError, TypeError, SyntaxError, ReferenceError]
		if error instanceof fatalType
			error.severity = 'fatal'

	switch
		when type.match /^notice/i
			error.severity = 'notice'
		when type.match /^warn/i
			error.severity = 'warning'
		else
			error.severity = 'fatal'
	
	error.text = 'Error'.red + ', '.grey

	if error.severity is 'fatal'
		error.text += error.severity.red
	else
		error.text += error.severity.yellow

	if scope
		error.text += ' in '.grey + scope.grey

	error.text += ': '.grey + msg

	if error.severity is 'fatal'
		error.text += '\n' + error.stack.grey

	return error

L.writeError = (text, rootDir = L.rootDir) ->
	if rootDir
		logPath	= path.join rootDir, '/error.log'
		errorBlock = "/err/#{new Date().toString()} #{text}\n"

		fs.appendFile logPath, errorBlock