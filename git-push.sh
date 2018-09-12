#!/bin/sh

set -e

certsdir=$1
repodir=`dirname "$certsdir"`

if [ x"$certsdir" = "x" -o "$certsdir" = "/" ]; then
        echo "$certsdir does not exists"
        exit 0
fi

which git > /dev/null || exit 0 

cd $repodir

git add "$certsdir"
if ! git diff-index --quiet HEAD --; then
        git tag -a $ver2 -m "version $ver2"
        git commit -a -m "Version $ver2"
        git push
        git push --tags
fi


