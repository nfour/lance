Promise = require 'bluebird'

{ merge, clone, typeOf } = utils = require 'lutils'

coroutiner = new require('coroutiner').Coroutiner { prototype: true }
coroutiner.transformer = Promise.coroutine

###
	Clone lutils then extend the new object
###
module.exports = utils = merge {
	format		: require './utils/format'
	prettyError	: require './utils/prettyError'
	exploreDir	: require './utils/exploreDir'
	coroutiner	: coroutiner
}, utils



#
# Debugging
#

utils.inspect = (vari, depth = 6, showHidden = true, colors = true) ->
	require('util').inspect vari, { depth, showHidden, colors }


