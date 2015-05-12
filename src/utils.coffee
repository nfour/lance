#
# Extended lutils
#

{ merge, clone, typeOf } = utils = require 'lutils'

###
	Clone lutils then extend the new object
###
module.exports = utils = merge {
	format		: require './utils/format'
	prettyError	: require './utils/prettyError'
	exploreDir	: require './utils/exploreDir'
	coroutiner	: new require('coroutiner').Coroutiner { prototype: true }
}, utils


#
# Debugging
#

utils.inspect = (vari, depth = 6, showHidden = true, colors = true) ->
	require('util').inspect vari, { depth, showHidden, colors }


