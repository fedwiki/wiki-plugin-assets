# assets plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
async = require 'async'

startServer = (params) ->
  app = params.app
  argv = params.argv

  # https://github.com/caolan/async/blob/v1.5.2/README.md#filter
  app.get '/plugin/assets/list', (req, res) ->
    path = "#{argv.assets}/#{req.query.assets}"
    isFile = (name, done) ->
      return done false if name.match /^\./
      fs.stat "#{path}/#{name}", (error, stats) ->
        return res {error} if error
        return done stats.isFile()
    fs.readdir path, (error, names) ->
      return res.json {error} if error
      async.filter names, isFile, (files) ->
        return res.json {files}

  app.get '/plugin/assets/:thing', (req, res) ->
    thing = req.params.thing
    res.json {thing}

module.exports = {startServer}
