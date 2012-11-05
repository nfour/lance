###
     __                     
    / /___  ____  ____ ___  
   / / __ `/ __ \/ ___/ _ \ 
  / / /_/ / / / / /__/  __/ 
 /_/\__/_/_/ /_/\___/\__/   
                            
###

path = require 'path'

request = require 'request'
require './functions' # exends natives, making functions avaliable

{clone, merge}	= Object
{requirer}		= Function

# project struct
lanceDir	= path.dirname __dirname
project		= requirer lanceDir, { paths: false, wrap: true }

# the core, private object
lance = {
	requirer: requirer
	session: {
		server: {}
	}
	
	error: (type, scope = '', msg = '') ->
		if arguments.length is 3
			return ">> #{type}, #{scope}: #{msg}"
		else if arguments.length is 2
			return ">> #{type}, #{scope}"
		else if arguments.length is 1
			return ">> #{type}"

	request: request
}

# the exposed, public object for user interaction 
# starts with minimal properties
# requirer is exposed so that it may be used immediately
lanceExports = {
	requirer: requirer

	init: (newCfg = {}) ->
		this.lance		= lance # add to the exports for the rest of the project to access
		this.session	= lance.session
		this.error		= lance.error
		this.request	= lance.request

		lance.project	= project
		project			= project._unwrap() # initializes the project

		lance.cfg		= merge clone( project.cfg.lance ), newCfg

		this.rootDir	=
		lance.rootDir	= lance.cfg.root or path.dirname require.main.filename

		this.lanceDir	=
		lance.lanceDir	= lanceDir

		lance.templating.init lance.cfg.templating or {}
		
		return this
}

module.exports = lanceExports

