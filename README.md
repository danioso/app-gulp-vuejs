app-gulp-vuejs
==============

Workflow to start, develop and deploy an application with gulp, Vue.js, CoffeeScript, Jade, Stylus, Browserify, TinyPNG.


## Install

Unless previously installed you'll need Cairo. For system-specific installation view the [node-canvas wiki](https://github.com/LearnBoost/node-canvas/wiki/_pages).

```shell
bower install
npm install
```

Signup for an API Key from https://tinypng.com/developers

```shell
export WEBAPP_PNG_COMPRESSION_SERVICE_KEY="API_KEY"
```

## Tasks

```shell

# Runing watch task and start server on localhost:9000 
gulp watch

# Runing build task (minify and rev files)
gulp build

# Runing build with tinypng compression service
gulp build --png-compression

# Runing publish to s3
gulp publish --service s3

```

