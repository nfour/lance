
path	= require 'path'
cluster	= require 'cluster'
fs		= require 'fs'


module.exports	=
lance			= (newCfg = {}) ->
	lance.cfg		= merge lance.cfg, newCfg
	lance.rootDir	= lance.cfg.root or path.dirname require.main.filename

	lance.templating lance.cfg.templating

	try Keygrip = require('keygrip') or false

	if Keygrip
		lance.requestHandler.keygrip = Keygrip lance.cfg.keygripKeys
	
	if lance.cfg.ascii and cluster.isMaster
		console.log """
			\       __                     
			\      / /___ _____  ________  
			\     / / __ `/ __ \\/ ___/ _ \\ 
			\    / / /_/ / / / / /__/  __/ 
			\   /_/\\__/_/_/ /_/\\___/\\___/  
			\                              
		"""

	if lance.cfg.catchUncaught
		process.on 'uncaughtException', (err) ->
			lance.error {
				type: 'uncaught'
				error: err
			}
	
	return lance

lance.cfg = require '../cfg/lance'

lance.error = () ->
	error = lance.error.parse arguments

	console.error error.text
	lance.error.write error.text

	if error.severity is 'fatal'
		process.kill()

	return error

lance.error.parse = (args) ->
	if typeOf( args[0] ) is 'object'
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

	if		type.match /^notice/i
		error.severity = 'notice'

	else if type.match /^warn/i
		error.severity = 'warning'

	else
		error.severity = 'fatal'

	for fatalType in [EvalError, TypeError, SyntaxError, ReferenceError]
		if error instanceof fatalType
			error.severity = 'fatal'
		
	if scope
		error.text = "[ #{error.severity} ] [ #{scope} ] #{msg}"
	else
		error.text = "[ #{error.severity} ] #{msg}"

	if error.severity is 'fatal'
		error.text += '\n' + error.stack

	return error

lance.error.write = (text, rootDir = lance.rootDir) ->
	if rootDir
		logPath	= path.join rootDir, '/error.log'
		errorBlock = "/err/#{new Date().toString()} #{text}\n"

		fs.appendFile logPath, errorBlock

lance.init		= lance
lance.session	= { server: {} }

require './utils'
{clone, merge, typeOf} = lance.utils

require './router'
require './templating'
require './server'


module.exports = lance

