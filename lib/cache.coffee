
L = require './lance'

{clone, typeOf} = L.utils

defaultTimeout = 1000 * 60 * 60

cache			=
module.exports	= {}

cache.count		= 0
cache.size		= 0
cache.threshold	= 1000
cache.data		= {}

cache.get = (key) ->
	return @data[key]?.value or undefined

cache.isSet = (key) ->
	return key of @data

cache.set = (key, value, timeout, frequency) ->
	if typeOf.Object arguments[0]
		{key, value, timeout, frequency} = arguments[0]

	if @count >= @threshold
		return false

	if key of @data
		@clearTimeout key
	else
		++@count

	@data[key] = {
		value
	}

	if timeout
		return @timeout key, timeout

	L.emit 'cache.set', arguments

	return true

cache.clear = (limit) ->
	count = 0
	for key, val of @data
		break if limit and count >= limit
		++count
		delete @data[key]

	@count = @count - count

	L.emit 'cache.clear', arguments

	return count

cache.purge = (key) ->
	if typeOf.RegExp key
		found = false
		for cacheKey of @data
			if cacheKey.match key
				found = true

				@remove cacheKey

		return found

	@remove key if key of @data
	
	L.emit 'cache.purge', arguments

	return false

# TODO: write a memory estimation function, run it over each new set value, 
# allow for maxSize and culling till it's arbitrarily half the size or
# perhaps also interface with node evn variable, determine the upper limit and work within it

# Below functions arent for public use. May want to make them private.

cache.remove = (key) ->
	--@count
	@clearTimeout key
	delete @data[key]

	return true

cache.clearTimeout = (key) ->
	clearTimeout @data[key].timeout if @data[key]?.timeout

cache.timeout = (key, time = defaultTimeout) ->
	@clearTimeout key

	@data[key].timeout = setTimeout (
		do (key) => =>
			@purge key
	), time
