// assets plugin - server-side component
// these handlers are launched with the wiki server.

import fs from 'node:fs'
import path from 'node:path'
import multer from 'multer'

const startServer = params => {
  const { app, argv } = params

  const upload = multer({ dest: path.join(argv.assets, 'uploads') })

  const authorized = (req, res, next) => {
    if (app['securityhandler'].isAuthorized(req)) {
      next()
    } else {
      res.status(403).send('must be owner')
    }
  }

  const cors = (req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*')
    next()
  }

  app.get('/plugin/assets/list', cors, (req, res) => {
    const assetsPath = path.join(argv.assets, (req.query.assets || '').match(/([\w/-]*)/)[1])
    fs.readdir(assetsPath, { withFileTypes: true }, (error, files) => {
      if (error) {
        return res.json({ error })
      }
      const filtered = files.filter(file => file.isFile()).map(file => file.name)
      return res.json({ error, files: filtered })
    })
  })

  app.get('/plugin/assets/index', cors, (req, res) => {
    const walk = dir => {
      const files = fs.readdirSync(path.join(argv.assets, dir), { withFileTypes: true })
      return files
        .map(file => {
          if (!file.name.startsWith('.')) {
            if (file.isFile()) {
              return {
                file: path.join(path.sep, dir, file.name),
                size: fs.statSync(path.join(argv.assets, dir, file.name)).size,
              }
            }
            if (file.isDirectory()) {
              return walk(path.join(dir, file.name)).flat()
            }
            return []
          } else {
            return []
          }
        })
        .flat()
    }

    return res.json(walk(''))
  })

  app.post('/plugin/assets/upload', authorized, upload.any(), (req, res) => {
    const assetsPath = path.join(argv.assets, (req.body.assets || '').match(/([\w/-]*)/)[1])
    fs.mkdirSync(assetsPath, { recursive: true })
    let errors = []
    req.files.forEach(element => {
      const uploaded = element.path
      const assetDestination = path.join(assetsPath, element.originalname)
      fs.rename(uploaded, assetDestination, err => {
        if (err) {
          errors.push(`rename failed for ${element.originalname}`)
        }
      })
    })
    if (errors.length > 0) {
      res.status(500).send(errors.join('\n'))
    } else {
      res.end('success')
    }
  })

  app.post('/plugin/assets/delete', authorized, (req, res) => {
    const file = path.basename(req.query.file || '')
    if (file) {
      const assets = (req.query.assets || '').match(/([\w/-]*)/)[1]
      const toRemove = path.join(argv.assets, assets, file)
      fs.unlink(toRemove, err => {
        if (err) {
          res.status(500).send(err.message)
        } else {
          res.status(200).send('ok')
        }
      })
    } else {
      res.status(500).send('No file specified')
    }
  })
}

export { startServer }
