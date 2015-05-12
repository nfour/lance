
{ spawn, spawnSync } = require 'child_process'

removePatterns = [ './lib', './data', './utils*']

# Builds coffeescript from ./src to ./
build = (args, done) ->
	cleanup()
	coffee = spawn 'coffee', args
	
	coffee.stdout.on 'data', (data) -> console.log data.toString()
	coffee.stderr.on 'data', (data) -> console.error data.toString()
	coffee.on 'exit', (status) -> done?() if status is 0

# Removes directories before writing to ensure pairity
cleanup = ->
	for pattern in removePatterns
		spawnSync 'rm', [ '-rf', pattern ]

task 'build', 'Build ./src to ./', ->
	build [ '-c', '-o', '.', './src' ]

task 'watch', 'Build ./src to ./ and watch', ->
	build [ '-wc', '-o', '.', './src' ]
	
task 'test::app', 'Runs a test server', ->
	require './test/app'