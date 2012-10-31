
path		= require 'path'

require './functions' # exends natives, making functions avaliable

# aliases
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
}

# the exposed, public object for user interaction 
# ---
# starts with minimal properties for simplicity
# requirer is exposed so that it may be used to retrieve
# lance's config if that's the case.
lanceExports = {
	requirer: requirer

	init: (newCfg = {}) ->
		this.lance		= lance					# add to the exports for the rest of the project to access
		this.session	= lance.session

		lance.project	= project
		lance.root		= process.env.startdir

		project			= project._unwrap()		# initializes the project

		lance.cfg		= merge clone( project.cfg.lance ), newCfg

		lance.templating.init lance.cfg.templating or {}
		
		return this
}

module.exports = lanceExports

