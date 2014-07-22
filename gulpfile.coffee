"use strict"

# Gulp
g 				= require('gulp')
$ 				= require('gulp-load-plugins') lazy:false
$.args 			= require('yargs').argv
$.sprite 		= require('css-sprite').stream
$.through2 		= require('through2')
$.fs 			= require('fs')
$.pkg 			= require('./package.json')

# Paths
path = 
	app: 'app/'
	dist: 'dist/'
	bower: 'bower_components/bower/'

# Vars
pngServiceKey 	= process.env.WEBAPP_PNG_COMPRESSION_SERVICE_KEY

# Arguments
pngService 		= Boolean $.args.pngCompression


# Check if png compression service is active
if pngService and !pngServiceKey 

	$.util.log 'Error: \n\n' + 
		'Entes de ejecutar gulp recuerda asignar un valor a la variable de entorno WEBAPP_PNG_COMPRESSION_SERVICE_KEY \n\n' + 
		'Puedes optener un token en la sigueinte página: https://tinypng.com/developers' + '\n'
	
	process.exit()

# Banner
banner = [
	'<!--'
	''
	'<%= pkg.homepage %>'
	'<%= pkg.name %> v<%= pkg.version %>'
	'<%= pkg.description %>'
	''
	'-->'
	''
].join '\n'
	
# Jade
g.task 'jade', ->

	g.src(path.app + '*.jade')
		.pipe $.plumber()
		.pipe $.jade({pretty:true})
		.pipe g.dest(path.dist)
		
# Stylus
g.task 'stylus', ->

	# All stylus files
	#g.src(path.app + 'styles/**/*.styl')
	g.src(path.app + 'styles/main.styl')
		.pipe $.plumber()
		.pipe $.stylus({use: ['nib']})
		.pipe g.dest(path.dist + 'styles')

# Bower dependencies
g.task 'bower', ['coffee'], ->

	g.src([
		path.bower + 'jquery/dist/jquery.min.js'
		path.bower + 'jquery/dist/jquery.min.map'
		]) 
		.pipe $.plumber()
		.pipe g.dest(path.dist + 'scripts/vendor/')

# Coffee
g.task 'coffee', ->

	g.src([path.app + 'scripts/main.coffee'], { read: false })
		.pipe $.plumber()
		.pipe $.browserify(
			transform: ['partialify', 'coffeeify']
			extensions: ['.coffee', '.html']
			shim: 
				'backbone':
					path: path.bower + 'backbone/backbone.js'
					exports: 'Backbone'
					depends:
						underscore: 'underscore'
				'underscore':
					path: path.bower + 'lodash/dist/lodash.js'
					exports: '_'
				'vue':
					path: path.bower + 'vue/dist/vue.min.js'
					exports: 'Vue'

			insertGlobals: true 
			debug: !$.util.env.production
		)
		.pipe $.rename('main.js')
		.pipe g.dest(path.dist + 'scripts/')

# Images & Sprite
g.task 'images-sprites', ['sprites'], ->
	
	g.start 'images'

# Sprites
g.task 'sprites', ->
	
	g.src(path.app + 'images/sprite/*.png')
		.pipe $.plumber()
	    .pipe $.sprite({
			name: 'sprite.png'
			style: 'sprite.styl'
			cssPath: '../images'
			processor: 'stylus'
		})
		.pipe $.if('*.png', g.dest(path.app + 'images/'))
		.pipe $.if('*.styl', g.dest(path.app + 'styles/lib/'))

# Images
g.task 'images', ->
	
	g.src(path.app + 'images/*.*')
		.pipe $.plumber()
		.pipe g.dest(path.dist + 'images/')

# Clean
g.task 'clean', ->

	g.src [path.dist], {read: false}
		.pipe $.clean()


# HTML Ref and Minify
g.task 'ref', ['default'], ->

	jsFilter = $.filter('**/*.js')
	cssFilter = $.filter('**/*.css')

	g.src(path.dist + '*.html')
		
		.pipe $.plumber()
		.pipe $.useref.assets()

		# JS
		.pipe jsFilter
		.pipe $.uglify()
		.pipe $.rev()
		.pipe jsFilter.restore()

		# CSS
		.pipe cssFilter
		.pipe $.minifyCss()
		.pipe $.rev()
		.pipe cssFilter.restore()

		# Output assets
		.pipe g.dest(path.dist + '')

		# Assets Manifest
		.pipe $.rev.manifest()

		# Useref replace
		.pipe $.useref.restore()
		.pipe $.useref()

		# HTML
		.pipe $.minifyHtml()

		# Output manifest and useref
		.pipe g.dest(path.dist)

g.task 'rev', ['ref'], ->

	# TODO, change to async?
	manifest = $.fs.readFileSync(path.dist + 'rev-manifest.json').toString()
	manifest = JSON.parse manifest

	regexp = RegExp("\\b(" + Object.keys(manifest).join("|") + ")\\b", "g")
	
	# TODO, create a gulp-rev-manifest?
	g.src(path.dist + '*.html')
		.pipe $.plumber()
		.pipe $.through2.obj((file, encoding, cb) ->

			file.contents = new Buffer(file.contents.toString().replace(regexp, (_, string) ->
				manifest[string]
			))

			@push file
			cb()
			return
		)
		.pipe $.header(banner, { pkg : $.pkg } )
		.pipe g.dest(path.dist)

g.task 'rev-clean', ['rev'], ->

	# TODO, change to async?
	manifest = $.fs.readFileSync(path.dist + 'rev-manifest.json').toString()
	manifest = JSON.parse manifest

	assets = [
		path.dist + 'styles/**.*'
		path.dist + 'scripts/**.*'
		path.dist + 'rev-manifest.json'
	]

	for key of manifest
		assets.push '!dist/' + manifest[key]

	# TODO, create a gulp-rev-manifest?
	g.src(assets)
		.pipe $.plumber()
		.pipe $.clean()

g.task 'image-min', ['rev-clean'], ->

	g.src(path.dist + 'images/*.png')
		.pipe $.plumber()

		# Depends on external API Service, only 500 request per month
		.pipe $.if(pngService, $.tinypng(pngServiceKey))

		# Extensions with bad compression D__D
		#.pipe $.imagemin({progressive:true,pngquant:true})
		#.pipe $.image()
		#.pipe $.optipng()
		
		.pipe g.dest(path.dist + 'images/')

	g.src(path.dist + 'images/*.jpg')
		.pipe $.plumber()
		.pipe $.imagemin({progressive:true})
		.pipe g.dest(path.dist + 'images/')

# Default
g.task 'default', ['jade', 'coffee', 'images-sprites', 'stylus', 'bower']

# Build
g.task 'build', ['clean'], ->
	g.start 'default', 'ref', 'rev', 'rev-clean', 'image-min'

# Deploy
g.task 'publish', ['build'], ->
	console.log 'starting deploy...'

# Server
g.task 'connect', ['default'], $.connect.server(
	root: [
		__dirname + "/bower_components/"
		__dirname + "/dist/"
	],
	port: 9000
	livereload: true
	open: 
		browser: 'Google Chrome'
)

# Static server, livereload and watch changes 
g.task 'watch', ['default', 'connect'], ->

	g.watch [
		path.dist + '*.html'
		path.dist + 'scripts/*.js'
		path.dist + 'styles/main.css'
		path.dist + 'images/*.*'
	], (event)->
		g.src(event.path)
			.pipe $.connect.reload()

	g.watch [
		path.app + '*.jade'
		path.app + 'layout/*.jade'
	], ['jade']

	g.watch [
		path.app + 'styles/**/*.styl'
	], ['stylus']

	g.watch [
		path.app + 'scripts/**/*.coffee'
	], ['coffee']

	g.watch [
		path.app + 'images/sprite/*.*'
	], ['sprites']

	g.watch [
		path.app + 'images/*.*'
	], ['images']

