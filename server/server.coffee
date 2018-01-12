# assets plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
async = require 'async'
multer = require 'multer'
upload = multer multer {dest: 'uploads/'}

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

  app.post '/plugin/assets/upload', upload.single('mumble'), (req, res) ->
    console.log(req.files);
    files = req.files.file
    if Array.isArray(files)
      # response with multiple files (old form may send multiple files)
      console.log 'Got ' + files.length + ' files'
    else
      # dropzone will send multiple requests per default
      console.log 'Got one file'
    res.sendStatus 200

  app.get '/plugin/assets/:thing', (req, res) ->
    thing = req.params.thing
    res.json {thing}

module.exports = {startServer}
