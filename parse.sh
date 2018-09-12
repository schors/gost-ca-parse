#!/bin/sh

set e

url="http://e-trust.gosuslugi.ru/CA/DownloadTSL?schemaVersion=0"
caxmlfile=$1
caxmlfile_new="${caxmlfile}.new"
certsdir=$2
certsdir_new="${certsdir}.new"
parser=$3
repodir=`basename ${certsdir}`

if [ ! -x "$parser" ]; then
        exit 0
fi

if [ x"$certsdir" = "x" -o "$certsdir" = "/" ]; then
        exit 0
fi

if [ x"$certsdir_new" = "x" -o "$certsdir_new" = "/" ]; then
        exit 0
fi

which wget > /dev/null || exit 0 
which xmllint > /dev/null || exit 0 
which git > /dev/null || exit 0 

cd $repodir

if wget -O $caxmlfile_new $url ; then
        ver1="0"
        if [ -e "$caxmlfile" ]; then
                ver1=`xmllint --xpath "//АккредитованныеУдостоверяющиеЦентры/Версия/text()" $caxmlfile`
        fi
        ver2=`xmllint --xpath "//АккредитованныеУдостоверяющиеЦентры/Версия/text()" $caxmlfile_new`
        if [ "$ver1" != "$ver2" ]; then
                if [ -d "$certsdir_new" ]; then
                        rm -rf "$certsdir_new"
                fi
                mkdir -p "$certsdir_new"
                if $parser -d "$certsdir_new" -x "$caxmlfile_new" >/dev/null 2>&1 ; then
                        mv -f $caxmlfile_new $caxmlfile
                        rm -rf "$certsdir"
                        mv -f "$certsdir_new" "$certsdir"
                        git add "$certsdir"
                        if ! git diff-index --quiet HEAD --; then
                                git commit -a -m "Version $ver2"
                                git push
                        fi
                fi
        else
                echo "Version not changed. Nothing to do"
        fi
fi
if [ -e "$caxmlfile_new" ]; then
        rm -f $caxmlfile_new
fi


