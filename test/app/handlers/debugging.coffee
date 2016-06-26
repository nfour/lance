usage = require 'usage'

formatMemory = (n) ->
	n = n / 1024
	n = Math.round( n * 100 ) / 100
	n = n.toString().replace /\B(?=(\d{3})+(?!\d))/g, ","
	n += ' kb'

formatCpu = (n) -> Math.round( n ) + '%'

history	= undefined

module.exports = showUsage = (done = ->) ->
	usage.lookup process.pid, (err, result) ->
		throw err if err

		console.log """
			#{ "USAGE".grey }\tMemory:\t#{ ( formatMemory result.memory ).green } #{ ( formatMemory result.memory - ( history?.memory or 0 ) ).yellow }
			\tCpu:\t#{ ( formatCpu result.cpu ).green } #{ ( formatCpu result.cpu - ( history?.cpu or 0 ) ).yellow }
		"""

		done history = result


