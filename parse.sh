#!/bin/sh

set -e

url="https://e-trust.gosuslugi.ru/CA/DownloadTSL?schemaVersion=0"
caxmlfile=$1
caxmlfile_new="${caxmlfile}.new"
certsdir=$2
certsdir_new="${certsdir}.new"
parser=$3
repodir=`dirname "$certsdir"`

logdate=`date +"%Y-%m-%dT%TZ%z"`

logit() {
        echo "${logdate}: $1"
}

if [ x"$certsdir" = "x" -o "$certsdir" = "/" ]; then
        logit "[-] $certsdir does not exists"
        exit 0
fi

if [ x"$certsdir_new" = "x" -o "$certsdir_new" = "/" ]; then
        logit "[-] $certsdir_new does not exists"
        exit 0
fi

if [ ! -x "$parser" ]; then
        logit "[-] $parser not exists or not executable"
        exit 0
fi

which wget > /dev/null || exit 0 
which xmllint > /dev/null || exit 0 

cd $repodir

if wget --quiet -O $caxmlfile_new $url ; then
        logit "[+] $url was fetched"
        ver1="0"
        if [ -e "$caxmlfile" ]; then
                ver1=`xmllint --xpath "//АккредитованныеУдостоверяющиеЦентры/Версия/text()" $caxmlfile`
        fi
        ver2=`xmllint --xpath "//АккредитованныеУдостоверяющиеЦентры/Версия/text()" $caxmlfile_new`
        if [ "$ver1" != "$ver2" ]; then
                logit "[=] Version changed: old=${ver1} new=${ver2}"
                if [ -d "$certsdir_new" ]; then
                        rm -rf "$certsdir_new"
                fi
                mkdir -p "$certsdir_new"
                if $parser -d "$certsdir_new" -x "$caxmlfile_new" >/dev/null 2>&1 ; then
                        logit "[+] Parsed successfully"
                        mv -f $caxmlfile_new $caxmlfile
                        rm -rf "$certsdir"
                        mv -f "$certsdir_new" "$certsdir"
                else
                        logit "[-] Parser error: $?"
                fi
        else
                logit "[=] Version not changed: old=${ver1} new=${ver2} Nothing to do"
        fi
else
        logit "[-] Can't fetch $url: $?"
fi
if [ -e "$caxmlfile_new" ]; then
        rm -f $caxmlfile_new
fi

