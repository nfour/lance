# v2.10.0
- Added `disabled` to the config for
	+ `templater.stylus`
	+ `templater.coffee`
	+ `templater.js`
	+ `templater.css`
	+ `templater.stylus`
	+ `templater.assets`
	
	When `true`, a disabled part will never be compiled or written to disk.
	This only applies to root compile targets, not dependencies.
	
- Added templater root directory to stylus import `paths`

## v2.9.0
- Removed `lance.httpcodes`, as I discovered `require('http').STATUS_CODES`

## v2.8.0
- Added config option `templater.browserify.transforms`
	+ When set, overwrites default `Coffeeify` and `Coffee-Reactify` transformers (provided they are require() able in the first place)
	+ Takes an array of an array of arguments to supply to `Browserify().transform`
	+ eg. `[ [ require('coffeeify'), { global: true } ] ]`
	
## v2.7.0
- Added config option `templater.assets.ignorePrefix = ''`.
	+ Folders and files starting with `_` were being ignored, now by default they are not and the prefix can be changed.