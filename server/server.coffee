# assets plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'

startServer = (params) ->
  app = params.app
  argv = params.argv

  app.get '/plugin/assets/list', (req, res) ->
    path = "#{argv.assets}/#{req.query.assets}"
    fs.readdir path, (error, files) ->
      return res.json {error} if error
      res.json {files}

  app.get '/plugin/assets/:thing', (req, res) ->
    thing = req.params.thing
    res.json {thing}

module.exports = {startServer}
