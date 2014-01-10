
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

L.utils = require './utils'

{clone, merge, typeOf} = L.utils

L.cfg = clone require '../cfg'

L.init = L

# The core event emitter
L.events	= new Emitter()
L.on		= L.events.on.bind L.events
L.emit		= L.events.emit.bind L.events

L.Tpl		= require './templating'
L.router	= require './router'
L.cache		= require './cache'

require './server'
require './exceptions'


