
path	= require 'path'
cluster	= require 'cluster'
fs		= require 'fs'
Keygrip = require 'keygrip'

require './functions' # exends natives, making functions avaliable

{clone, merge} = Object
{type} = Function

defaultCfg = require '../cfg/lance'

module.exports	=
lance			= (newCfg = {}) ->
	lance.cfg		= merge clone( defaultCfg ), newCfg
	lance.rootDir	= lance.cfg.root or path.dirname require.main.filename

	lance.templating lance.cfg.templating or {}

	lance.keygrip = Keygrip lance.cfg.keygripKeys
	
	if lance.cfg.ascii and cluster.isMaster
		console.log """
			\       __                     
			\      / /___ _____  ________  
			\     / / __ `/ __ \\/ ___/ _ \\ 
			\    / / /_/ / / / / /__/  __/ 
			\   /_/\\__/_/_/ /_/\\___/\\___/  
			\                              
		"""

	if lance.cfg.catchUncaughtErrors
		process.on 'uncaughtException', (err) ->
			lance.error {
				type: 'uncaught'
				error: err
			}

	return lance

lance.error = () ->
	if type( arguments[0] ) is 'object'
		opt = arguments[0]
	else
		if arguments[0] instanceof Error
			opt = { error: arguments[0] }
		else
			opt = { type: arguments[0], error: arguments[1] }

	opt.type = opt.type or 'warning'

	if		opt.type.match /^notice/i
		errType = 'Notice'
	else if opt.type.match /^warn/i
		errType = 'Warning'
	else if opt.type.match /^(err|fatal)/i
		errType = 'Fatal'
	else if opt.type.match /^(uncaught)/i
		errType = 'Uncaught'
	else
		errType = 'Error'

	scope	= opt.scope or ''
	error	= opt.error or ''

	if error not instanceof Error
		error = new Error 'Unknown'

	msg = error.message or ''

	for fatalType in [EvalError, TypeError, SyntaxError, ReferenceError]
		if error instanceof fatalType
			errType = 'Fatal'

	if scope
		errStr = "[ #{errType} ] [ #{scope} ] #{msg}"
	else
		errStr = "[ #{errType} ] #{msg}"

	if errType.match /^(uncaught|fatal|err)/i
		errStr += '\n' + error.stack

	console.error errStr

	lance.error.write errStr

	return new Error

lance.error.write = (errStr) ->
	if lance.rootDir
		logPath	= lance.rootDir + '/error.log'
		line	= new Date().toString() + ' - ' + errStr + '\n'

		fs.appendFile logPath, line

lance.init		= lance
lance.session	= { server: {} }

require './router'
require './templating'
require './server'
require './respond'

module.exports = lance

