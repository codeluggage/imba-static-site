# Building Imba for static hosting

This is a starting point for building Imba to be hosted statically. It can also be used to build Imba into a native app with [imbutter](https://github.com/codeluggage/imbutter).

Original `build.js` script is here: <https://gist.github.com/trafnar/05ebbf0f5193e69f998f41b154d18190>

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.
You will also see any lint errors in the console.

### `npm run build`

Builds the app for production to the `dist` folder.

Note that `dist/html` is the static version.

## Deployment

### Github Pages

#### TLDR
Create a new github repository and replace `YOUR_NEW_GITHUB_REPO_URL` with your new repo's url.
```
npx imba create project_name
cd project_name
git add --all
git commit -m "initial commit"
git remote add origin YOUR_NEW_GITHUB_REPO_URL
git push -u origin main

npx imba build --baseurl . server.imba
npx touch dist/public/.nojekyll
npx gh-pages --no-history --dotfiles --dist dist/public
```
To find the URL your project has been deployed to, navigate to the `Pages` tab of your repo's settings.

#### Explanation
For static hosting, we build using `.` as the baseurl.
```
npx imba build --baseurl . server.imba
```
Yes, we still build using the `server.imba` file even though we won't be using any of the server-side files.

Since Github Pages uses Jekyll by default, paths starting with underscores (like `__assets__`) will fail to load, so we have to that specify we don't want to use Jekyll by doing:
```
npx touch dist/public/.nojekyll
```
Once all of that is settled, actually deploying to github pages is really easy with `npx gh-pages`, which will create a new git branch named `gh-pages` and serve our files from there by default.

- For our purposes, it's important to specify `--dotfiles` because of the necessary `.nojekyll` file.
- We also want to use `dist/public` as the base directory.
- Since we don't need the `gh-pages` branch for actual version control, I prefer to use the `--no-history` flag as well.

```
npx gh-pages --no-history --dotfiles --dist dist/public
```