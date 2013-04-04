###
     __                     
    / /___  ____  ____ ___  
   / / __ `/ __ \/ ___/ _ \ 
  / / /_/ / / / / /__/  __/ 
 /_/\__/_/_/ /_/\___/\__/   
                            
###

path	= require 'path'
cluster	= require 'cluster'
ect		= require 'ect'

require './functions' # exends natives, making functions avaliable

{clone, merge} = Object

# project struct
defaultCfg = require '../cfg/lance'

# the core, private object
module.exports	=
lance			= (newCfg = {}) ->
	lance.cfg		= merge clone( defaultCfg ), newCfg
	lance.rootDir	= lance.cfg.root or path.dirname require.main.filename

	lance.templating.init lance.cfg.templating or {} # make this function oriented ########################
	
	if lance.cfg.ascii and cluster.isMaster
		console.log """
		\       __                     
		\      / /___ _____  ________  
		\     / / __ `/ __ \\/ ___/ _ \\ 
		\    / / /_/ / / / / /__/  __/ 
		\   /_/\\__/_/_/ /_/\\___/\\___/  
		\                              
		"""
	return lance

lance.init		= lance
lance.session	= { server: {} }

require './exceptions'
require './router'
require './templating'
require './server'
require './respond'

module.exports = lance

