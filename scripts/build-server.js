import * as esbuild from 'esbuild'
import fs from 'node:fs/promises'
import packJSON from '../package.json' with { type: 'json' }

const version = packJSON.version
const now = new Date()

let results = await esbuild.build({
  entryPoints: ['src/server/server.js'],
  bundle: false,
  platform: 'node',
  banner: {
    js: `/* wiki-plugin-assets - ${version} - ${now.toUTCString()} */`,
  },
  minify: true,
  sourcemap: true,
  logLevel: 'info',
  metafile: true,
  outfile: 'server/server.js',
})

await fs.writeFile('meta-server.json', JSON.stringify(results.metafile))
console.log("\n  esbuild metadata written to 'meta-server.json'.")
