module.exports ={
	server:
		port	: 1337
		static	: './static'
		
	root	: __dirname
	
	logging:
		debug:
			render: true
			files: true
	
	templater:
		findIn	: './views'
		saveTo	: './static'
		
		locals:
			test2: 2
		
		debug:
			files: true
			render: true
			
		bundle:
			"style.css"	: "./_css/style.styl"
			"app.js"	: "./_js/app.coffee"
		
		templater:
			options:
				cache	: true
				watch	: true
				open	: '<<'
				close	: '>>'

}