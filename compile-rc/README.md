# Runbook

## To generate a new release

```sh
yarn compile --write --commit
```

## Bumping major and minor versions
Run the following to set a new version without tagging and committing

This ensures we do not mess up the automatic tagging done in `compile.js`

```sh
yarn version --minor --no-git-tag-version
yarn version --major --no-git-tag-version
```

Then commit the new version to repo
