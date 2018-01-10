# assets plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
async = require 'async'

startServer = (params) ->
  app = params.app
  argv = params.argv

  app.get '/plugin/assets/list', (req, res) ->
    path = "#{argv.assets}/#{req.query.assets}"
    isFile = (name, done) ->
      fs.stat "#{path}/#{name}", (error, stats) ->
        return done error if error
        done null, stats.isFile()
    fs.readdir path, (error, names) ->
      return res.json {error} if error
      async.filter names, isFile, (err, files) ->
        res.json {files}

  app.get '/plugin/assets/:thing', (req, res) ->
    thing = req.params.thing
    res.json {thing}

module.exports = {startServer}
