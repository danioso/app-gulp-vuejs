Vue = require('vue')
html = require('./app.html')

main = 

  # Component DOM Element ID
  el: '#app'

  # List of components attached to it
  components:
    a: require('./components/a/a') 
    b: require('./components/b/b')

  # Template
  template: html 

  # Model
  data:
    title: 'App title'

# Inititalize main component
new Vue main
