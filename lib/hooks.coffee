
lanceExports	= require 'lance'
lance			= lanceExports.lance

exports = {
	server: {
		request	: (req, res) ->
		respond	: (req, res, opt) ->
		serve	: (req, res, opt) ->
	}
	
}

# extend lance

lance.hooks			= exports
lanceExports.hooks	= exports

module.exports = exports