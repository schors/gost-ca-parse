#!/bin/sh

set -e

caxmlfile=$1
certsdir=$2
repodir=`dirname "$certsdir"`

logdate=`date +"%Y-%m-%dT%TZ%z"`

logit() {
        echo "${logdate}: $1"
}

if [ x"$certsdir" = "x" -o "$certsdir" = "/" ]; then
        logit "[-] $certsdir does not exists"
        exit 1
fi

if [ ! -e "$caxmlfile" ]; then
        logit "[-] XML-file ${caxmlfile} not found"
        exit 1
fi

which git > /dev/null || exit 0 
which xmllint > /dev/null || exit 0

cd $repodir

ver=`xmllint --xpath "//АккредитованныеУдостоверяющиеЦентры/Версия/text()" $caxmlfile`

git stash
git pull
git stash apply
git add "$certsdir"
if ! git diff-index --quiet HEAD --; then
        logit "[+] Commit and push Version $ver"
        git commit -a -m "Version $ver"
        git tag -a $ver -m "version $ver"
        git push --follow-tags
else
        logit "[=] Nothing to do"
fi

