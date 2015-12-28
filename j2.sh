#!/bin/bash

JOURNAL_DIR=${JOURNAL_DIR:-$HOME/journal}
GPG_NAME=${GPG_NAME:-$USER}
DO_SILLY_TITLE=${DO_SILLY_TITLE:-1}
DO_ENCRYPT=${DO_ENCRYPT:-1}

while [ $# -gt 0 ]; do 
    case $1 in
        -r)
            shift
            readlist=${readlist:-$JOURNAL_DIR/*}
            doread=true
            ;;
        -e)
            shift
            readlist=`grep -e $1 -l $JOURNAL_DIR/*`
            shift
            ;;
        *)
            title="$title $1"
            shift
            ;;
    esac
done

if [ $doread ] ; then
    cat $readlist | less
    exit
fi

COLUMNS=80
center()
{
     value=${#1} 
     if [[ $value -lt $COLUMNS ]] ; then
       width=$(( (  $COLUMNS + $value ) / 2 ))
       printf "%${width}s\n"  "$1"
     else
        echo "$1"
     fi
}

plain_title()
{
    tit="${1}"
    out="${2}"
    bar=`echo "$tit" | sed s/./-/g`
    center "  +$bar+  " >> "${out}"
    center "-= $tit =-" | tr '[a-z]' '[A-Z]' | cat >> "${out}"
    center "  +$bar+  " >> "${out}"
}

if [ ! -d $JOURNAL_DIR ] ; then
    echo Making journal directory: $JOURNAL_DIR
    mkdir $JOURNAL_DIR
fi
cd $JOURNAL_DIR

fname=`date +%Y%m%d%H%M%S`
timestamp=`date --rfc-3339=seconds 2>/dev/null`
if [ ! $? -eq 1 ] ; then
    timestamp=`date +%Y-%m-%d %H:%M:%S%z 2>/dev/null`
fi

dt=`mktemp`

# `dt' is just where we put the 
# Date and Title
title="${title:============}"

case $(( ($RANDOM % 19) * $DO_SILLY_TITLE)) in
    0)
        plain_title "$title" ${dt}
        ;;
    1)
        cowsay -f "eyes" "$title" >>${dt}
        ;;
    2)
        cowsay -f "tux" "$title" >>${dt}
        ;;
    3)
        cowsay -f "kitty" "$title" >>${dt}
        ;;
    4)
        cowsay -f "bong" "$title" >>${dt}
        ;;
    *)
        plain_title "$title" ${dt}
        ;;
esac
echo >>${dt}
echo >>${dt}
echo --$USER >>${dt}
echo $timestamp >>${dt}
vim_newentry_map="nmap ,l o<ESC>!!date +\\\\%_H\\\\%M<CR>i<End>"
case $EDITOR in
    *vim|*vi)
        vim +"read ${dt}" +"set wrap" +"set spell" +"exec \"$vim_newentry_map\"" +"startinsert" +"set tw=0" +/^$/ $fname
        ;;
    *nano)
        cat ${dt} | $EDITOR --softwrap $fname
        ;;
    *)
        $EDITOR $fname
        ;;
esac

exit

# remove temporary file
rm ${dt}

if [ -e $fname ] ; then
    tmp0=`mktemp`
    tmp1=`mktemp`
    # the gpg line assumes your username is in your keyring
    fold -s $fname > $tmp0
    if [ $DO_ENCRYPT -eq 1 ] ; then
        echo Encrypting entry for $GPG_NAME
        gpg -e -r $GPG_NAME < $tmp0 > $tmp1
    else
        cat < $tmp0 > $tmp1
    fi
    mv ${tmp1} $fname
    rm ${tmp0}
else
    echo Did not create journal entry
fi

# Clean up vim swap files
if [ -e .$day.sw? ] ; then
    rm -v .$day.sw?
fi
