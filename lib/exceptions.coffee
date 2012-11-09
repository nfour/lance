
lanceExports	= require 'lance'
lance			= lanceExports.lance

exports = {
	error: (type, scope = '', msg...) ->
		if arguments.length >= 3
			result = "!! [ #{type} ] in [ #{scope} ]: #{msg.join ' '}"
		else if arguments.length is 2
			result = "!! [ #{arguments[0]} ] in [ #{scope} ]"
		else if arguments.length is 1
			result = "!! #{arguments[0]}"

		console.error result
		return result
}

publicExports = {
	error: -> lance.error.apply lance, arguments
}

# extend lance

lance.error			= exports.error
lanceExports.error	= publicExports.error

module.exports = exports