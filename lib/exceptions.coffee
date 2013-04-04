
lance	= require './lance'
fs		= require 'fs'

lance.error = (type, scope = '', msg...) ->
	if arguments.length >= 3
		result = "!! #{type} in #{scope}: #{msg.join ' '}"
	else if arguments.length is 2
		result = "!! #{arguments[0]} in #{scope}"
	else if arguments.length is 1
		result = "!! #{arguments[0]}"
	
	console.error result
	
	return result

process.on 'XuncaughtException', (err) ->
	console.error 'uncaughtException:', err
	
	if lance.rootDir
		logPath	= lance.rootDir + '/errors.txt'
		line	= new Date().toString() + ' -- ' + err + '\n'

		fs.appendFile logPath, line

