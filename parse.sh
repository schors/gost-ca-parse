#!/bin/sh

set -e

url="https://e-trust.gosuslugi.ru/CA/DownloadTSL?schemaVersion=0"
caxmlfile=$1
caxmlfile_new="${caxmlfile}.new"
certsdir=$2
certsdir_new="${certsdir}.new"
parser=$3
repodir=`dirname "$certsdir"`

if [ x"$certsdir" = "x" -o "$certsdir" = "/" ]; then
        echo "$certsdir does not exists"
        exit 0
fi

if [ x"$certsdir_new" = "x" -o "$certsdir_new" = "/" ]; then
        echo "$certsdir_new does not exists"
        exit 0
fi

if [ ! -x "$parser" ]; then
        echo "$parser not exists or not executable"
        exit 0
fi

which wget > /dev/null || exit 0 
which xmllint > /dev/null || exit 0 

cd $repodir

if wget --quiet -O $caxmlfile_new $url ; then
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
                fi
        else
                echo "Version not changed. Nothing to do"
        fi
fi
if [ -e "$caxmlfile_new" ]; then
        rm -f $caxmlfile_new
fi


