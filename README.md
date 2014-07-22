app-gulp-vuejs
==============

Workflow to start, develop and deploy an application with gulp, Vue.js, CoffeeScript, Jade, Stylus, Browserify, TinyPNG.


## Install

Unless previously installed you'll need Cairo. For system-specific installation view the [node-canvas wiki](https://github.com/LearnBoost/node-canvas/wiki/_pages).

```shell
$ npm install
$ bower install
```

Set the following environment variable, you will an API Key from TinyPNG to compress png files [https://tinypng.com/developers](https://tinypng.com/developers)

```shell
$ export WEBAPP_PNG_COMPRESSION_SERVICE_KEY="API_KEY"
```

## Tasks

Runing watch task to develop.
```shell
$ gulp watch
```
Runing build task to get files ready for production.
```shell
$ gulp build
```
Runing build with tinypng compression service
```shell
$ gulp build --png-compression
```


