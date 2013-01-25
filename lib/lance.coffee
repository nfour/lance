###
     __                     
    / /___  ____  ____ ___  
   / / __ `/ __ \/ ___/ _ \ 
  / / /_/ / / / / /__/  __/ 
 /_/\__/_/_/ /_/\___/\__/   
                            
###

path = require 'path'

require './functions' # exends natives, making functions avaliable

{clone, merge}	= Object

# project struct
defaultCfg = require '../cfg/lance'

# the core, private object
module.exports	=
lance			= (newCfg = {}) ->
	lance.cfg		= merge clone( defaultCfg ), newCfg
	lance.rootDir	= lance.cfg.root or path.dirname require.main.filename

	lance.templating.init lance.cfg.templating or {} # make this function oriented ########################
	
	return lance

lance.init		= lance
lance.requirer	= require './requirer'
lance.session	= { server: {} }

require './hooks'
require './exceptions'
require './router'
require './templating'
require './server'
require './respond'

module.exports = lance

