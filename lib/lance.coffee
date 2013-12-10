
path	= require 'path'
cluster	= require 'cluster'
fs		= require 'fs'
Emitter	= require('eventemitter2').EventEmitter2
require 'colors'

module.exports	=
L				= (newCfg) ->
	L.initiated = true

	# merges the two configs together, overwriting the defaults

	merge L.cfg, newCfg if newCfg
	cfg = L.cfg

	L.rootDir = cfg.rootDir or path.dirname require.main.filename

	# Make sure we make cfg.server.cluster a bool
	
	cfg.server.workers = cfg.server.workerLimit if cfg.server.workerLimit

	if cfg.server.cluster is null
		if cfg.server.workers < 2
			cfg.server.cluster = false
		else
			cfg.server.cluster = true

	# Backwards compat with old workerLimit property name

	# Initiates the templating, which begins watching files, compiles them first etc.
	L.tpl = new L.Tpl cfg.tpl or cfg.templating

	try
		Keygrip = require('keygrip')
		L.requestHandler.keygrip = Keygrip cfg.keygripKeys

	if cfg.catchUncaught
		process.on 'uncaughtException', (err) ->
			L.error {
				type: 'uncaught'
				error: err
			}
	
	return L

L.cfg = require '../cfg'


L.error = ->
	error = L.error.parse arguments

	L.emit 'error', error

	console.error error.text
	L.error.write error.text

	if error.severity is 'fatal'
		process.exit(0)

	return error

L.error.notice = ->
	error = L.error.parse arguments

	L.emit 'error', error

	console.error error.text
	L.error.write error.text

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

	if		type.match /^notice/i
		error.severity = 'notice'

	else if type.match /^warn/i
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

L.error.write = (text, rootDir = L.rootDir) ->
	if rootDir
		logPath	= path.join rootDir, '/error.log'
		errorBlock = "/err/#{new Date().toString()} #{text}\n"

		fs.appendFile logPath, errorBlock

L.init = L

# The core event emitter
L.events	= new Emitter()
L.on		= L.events.on.bind L.events
L.emit		= L.events.emit.bind L.events

L.utils		= require './utils'
L.Tpl		= require './templating'
L.router	= require './router'

require './server'

{clone, merge, typeOf} = L.utils

