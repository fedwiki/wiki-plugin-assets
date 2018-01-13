# assets plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
async = require 'async'
formidable = require 'formidable'

startServer = (params) ->
  app = params.app
  argv = params.argv

  app.get '/plugin/assets/list', (req, res) ->
    path = "#{argv.assets}/#{req.query.assets}"
    isFile = (name, done) ->
      return done false if name.match /^\./
      fs.stat "#{path}/#{name}", (error, stats) ->
        return done error if error
        return done null, stats.isFile()
    fs.readdir path, (error, names) ->
      return res.json {error} if error
      async.filter names, isFile, (error, files) ->
        return res.json {error, files}

  app.post '/plugin/assets/upload', (req, res) ->
    return res.status(401).send("must login") unless req.session?.passport?.user || req.session?.email || req.session?.friend
    form = new (formidable.IncomingForm)
    form.multiples = true
    form.uploadDir = "#{argv.assets}"
    form.on 'field', (name, value) ->
      form.uploadDir = "#{argv.assets}/#{value}" if name == 'assets'
    form.on 'file', (field, file) ->
      fs.rename file.path, "#{form.uploadDir}/#{file.name}"
    form.on 'error', (err) ->
      console.log "upload error: #{err}"
      res.status(500).send("upload error: #{err}")
    form.on 'end', ->
      res.end 'success'
    form.parse req

  app.get '/plugin/assets/:thing', (req, res) ->
    thing = req.params.thing
    res.json {thing}

module.exports = {startServer}
