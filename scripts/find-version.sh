#!/bin/sh

# VERSION is required
VERSION=$1
if [ ! "$VERSION" ]; then
   echo "Please input a version search string. Try \`yarn find-version 1.4.1601160553209\`"
   exit 1
fi

SHA=$(git grep $VERSION $(git rev-list --all) | tail -1 | awk 'BEGIN { FS = ":" } ; { print $1 }')

# show logs between version and head
git log --pretty=oneline -n 20 --graph --color $SHA..


