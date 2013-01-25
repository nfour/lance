
lance = require './lance'

lance.hooks = {
	server: {
		request	: (req, res) ->
		respond	: (req, res, opt) ->
		serve	: (req, res, opt) ->
	}
	
}
