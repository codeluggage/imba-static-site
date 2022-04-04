const util = require('util')
const childProcess = require('child_process')
const fs = require('fs-extra')
const path = require('path')

const exec = util.promisify(childProcess.exec)

async function runBuild () {
  const targetPath = './dist/html'

  // clear out build directory

  try {
    await fs.rmdir('./dist/', { recursive: true })
  } catch (e) {
    console.log(e)
  }

  // run the imba build command
  await exec('imba build --baseurl "." server.imba')
    .catch(e => console.log('imba build error'))
    .then(e => {
      console.log('imba build done\n', e)
    })

  // make a directory to store my custom build
  console.log('Making dir to store build at', targetPath)
  await fs.mkdirs(targetPath)

  // move my custom assets folder contents over
  console.log('Moving contents of /public (assets folder)')
  try {
    await fs.copy('./public/', targetPath, {
      overwrite: false,
      errorOnExist: true
    })
  } catch (e) {
    console.log(e)
  }

  // move and rename the HTML file
  console.log(
    'moving ./dist/public/index.html to ',
    path.join(targetPath, 'index.html')
  )
  await fs.rename(
    './dist/public/index.html',
    path.join(targetPath, 'index.html')
  )

  // find the CSS file and move it
  const cssBasePath = './dist/public/__assets__/'
  const cssFileName = await findFileByRegex(cssBasePath, /all-.*\.css/)
  console.log('finding css file at', cssBasePath, cssFileName)

  // move and rename the CSS file
  console.log(
    'move css file, from:',
    path.join(cssBasePath, cssFileName),
    'to:',
    path.join(targetPath, 'style.css')
  )
  await fs.rename(
    path.join(cssBasePath, cssFileName),
    path.join(targetPath, 'style.css')
  )

  // find the JS file
  console.log('find the js file')
  const jsBasePath = './dist/public/__assets__/app/'
  const jsFileName = await findFileByRegex(jsBasePath, /client\-.*\.js$/, true)

  // remove sourcemap reference from script
  console.log('remove sourcemap reference from script')
  await replaceTextInFile(
    path.join(jsBasePath, jsFileName),
    /\/\/#\ssourceMapping.*/,
    '',
    true
  )
  console.log(jsBasePath, jsFileName)

  // move and rename the JS file
  console.log('move and rename the js file')
  await fs.rename(
    path.join(jsBasePath, jsFileName),
    path.join(targetPath, 'client.js')
  )

  // remove the type="module" attribute from the script tag
  console.log('remove type=module attribute from script tag')
  await replaceTextInFile(
    path.join(targetPath, 'index.html'),
    'type="module" ',
    ''
  )

  // update filename in script tag
  console.log('update filename in script tag')
  const existingScriptTagSrc = path.join('./__assets__/app/', jsFileName)
  await replaceTextInFile(
    path.join(targetPath, 'index.html'),
    existingScriptTagSrc,
    'client.js'
  )

  // update filename in style tag
  const existingLinkTagHref = path.join('./__assets__/', cssFileName)
  console.log('update filename in style tag', existingLinkTagHref)
  await replaceTextInFile(
    path.join(targetPath, 'index.html'),
    existingLinkTagHref,
    'style.css'
  )

  console.log('remove hmr.js')
  await replaceTextInFile(
    path.join(targetPath, 'index.html'),
    /<script src=\'\/__hmr__\.js\'><\/script>/,
    ''
  )

  console.log('move all assets')
  const assetsList = await fs.readdir('./dist/public/__assets__')
  for (let fileName of assetsList) {
    console.log(fileName)
    await fs.rename(
      path.join('./dist/public/__assets__/', fileName),
      path.join(targetPath, fileName)
    )
  }

  console.log('update asset paths')
  await replaceTextInFile(
    path.join(targetPath, 'style.css'),
    /\.\/__assets__\//g,
    ''
  )
}

async function replaceTextInFile (path, regex, replaceWith, debug = false) {
  const data = await fs.readFile(path, 'utf8')
  const result = data.replace(regex, replaceWith)
  await fs.writeFile(path, result, 'utf8')
}

async function findFileByRegex (base, regex, log = false) {
  const files = await fs.readdir(base)
  const filtered = files.filter(function (filePath) {
    const result = filePath.match(regex) !== null
    if (result) {
      return filePath
    }
  })
  return filtered[0]
}

process.on('unhandledRejection', (reason, p) => {
  console.log('Unhandled Rejection at: Promise', p)
  // application specific logging, throwing an error, or other logic here
})

runBuild()
