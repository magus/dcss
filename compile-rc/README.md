# Runbook

After making edits to [`_template.rc`](https://github.com/magus/dcss/blob/master/compile-rc/_template.rc) or the associated files under the [`parts`](https://github.com/magus/dcss/tree/master/compile-rc/parts) directory, you can run `yarn compile` to build the new customized RC file. It will also be **copied to your clipboard** for your convenience.

## Generate local rc

generate a local rc for testing or personal use

```sh
# Edit `_template.rc` and/or associated `parts` files
yarn compile
# That's it! Your customized RC is now on your clipboard ready for pasting
```
## Generate new release

```sh
yarn compile --write --commit
```

## Bump major|minor version
Run the following to set a new version without tagging and committing

This ensures we do not mess up the automatic tagging done in `compile.js`

```sh
yarn version --minor --no-git-tag-version
yarn version --major --no-git-tag-version
```

Then commit the new version to repo
