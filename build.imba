# https://gist.github.com/trafnar/05ebbf0f5193e69f998f41b154d18190

###
You can have a folder at the root of your project called "public" which will have any assets you
want copied over to the build folder, things like favicons or other static files that you aren't importing
into your imba project somewhere.
###

const path = require("path")
const childProcess = require("child_process")
const exec = require("util").promisify(childProcess.exec)

# 'fs-extra' is a package you need to install as a dev dependency,
# it makes dealing with the filesystem easier
const fs = require("fs-extra")

const TARGET_PATH = "./dist/html"

def runBuild

	# clear out the build directory
	await fs.rmdir "./dist/", {recursive: true}

	# run the imba build command
	try
		await exec('imba build --baseurl "." server.imba')
		console.log "Imba build done\n"
	catch e
		console.log "Imba build done with errors:", e
		return
	
	# make a directory to store the custom build
	console.log "making directory to store custom build at", TARGET_PATH
	await fs.mkdirs(TARGET_PATH)

	# move custom assets folder contents over
	if await fs.pathExists("./public/")
		console.log("Moving contents of /public (assets folder)")
		await fs.copy("./public/", TARGET_PATH, {overwrite: false, errorOnExist: true})
	else
		console.log("no /public (assets folder) found")

	# move and rename the HTML file
	console.log( "moving ./dist/public/index.html to:", path.join(TARGET_PATH, "index.html"))
	await fs.rename("./dist/public/index.html", path.join(TARGET_PATH, "index.html"))

	# find the CSS file and move it
	const cssBasePath = "./dist/public/__assets__/"
	const cssFileName = await findFileByRegex(cssBasePath, /all-.*\.css/)
	console.log("finding css file at", cssBasePath, cssFileName)

	# move and rename the CSS file
	const cssPath = path.join(TARGET_PATH, "style.css")
	console.log "move css file, from:", path.join(cssBasePath, cssFileName), "to:", cssPath
	await fs.rename(path.join(cssBasePath, cssFileName), cssPath)

	# find the JS file
	console.log("find the js file")
	const jsBasePath = "./dist/public/__assets__/app/"
	const jsFileName = await findFileByRegex(jsBasePath, /client\-.*\.js$/, true)

	# remove sourcemap reference from script
	console.log("remove sourcemap reference from script")
	await replaceTextInFile(path.join(jsBasePath, jsFileName), /\/\/#\ssourceMapping.*/, "", true)

	# move and rename the JS file
	console.log("move and rename the js file")
	await fs.rename(path.join(jsBasePath, jsFileName), path.join(TARGET_PATH, "client.js"))

	# remove the type="module" attribute from the script tag
	console.log("remove type=module attribute from script tag")
	await replaceTextInFile(path.join(TARGET_PATH, "index.html"), 'type="module" ', "")

	# update filename in script tag
	console.log("update filename in script tag")
	const existingScriptTagSrc = path.join("./__assets__/app/", jsFileName)
	await replaceTextInFile( path.join(TARGET_PATH, "index.html"), existingScriptTagSrc, "client.js")

	# update filename in style tag
	const existingLinkTagHref = path.join("./__assets__/", cssFileName)
	console.log("update filename in style tag", existingLinkTagHref)
	await replaceTextInFile( path.join(TARGET_PATH, "index.html"), existingLinkTagHref, "style.css")

	console.log("remove hmr.js")
	await replaceTextInFile( path.join(TARGET_PATH, "index.html"), /<script src=\'\/__hmr__\.js\'><\/script>/, "")

	console.log("move all assets")
	const assetsList = await fs.readdir("./dist/public/__assets__")
	for fileName in assetsList
		console.log(fileName)
		await fs.rename( path.join("./dist/public/__assets__/", fileName), path.join(TARGET_PATH, fileName))

	console.log("update asset paths")
	await replaceTextInFile( path.join(TARGET_PATH, "style.css"), /\.\/__assets__\//g, "")


def replaceTextInFile(path, regex, replaceWith, debug = false)
	const data = await fs.readFile(path, "utf8")
	const result = data.replace(regex, replaceWith)
	await fs.writeFile(path, result, "utf8")

def findFileByRegex(base, regex, log = false)
	const files = await fs.readdir(base)
	const filtered = files.filter do(filePath)
		const result = filePath.match(regex) !== null
		return filePath if result
	return filtered[0]

# catch unhandled promise rejections so we can show some error messaging
process.on "unhandledRejection" do(reason, p)
	console.log("Unhandled Rejection at:", p)

runBuild()