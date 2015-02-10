#!/bin/bash

JOURNAL_DIR=$HOME/journal
GPG_NAME=${GPG_NAME:-$USER}

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

cd $JOURNAL_DIR

fname=`date +%Y%m%d%H%M%S`
timestamp=`date --rfc-3339=seconds`

#title="$@"
# `dt' is just where we put the 
# Date and Title
title="${title:============}"
case $(( $RANDOM % 19)) in
    0)
        cowsay -f "eyes" $title >>dt
        ;;
    1)
        cowsay -f "tux" $title >>dt
        ;;
    2)
        cowsay -f "kitty" $title >>dt
        ;;
    3)
        cowsay -f "bong" $title >>dt
        ;;
    *)
        bar=`echo "$title" | sed s/./-/g`
        center "  +$bar+  " >> "dt"
        center "-= $title =-" | tr '[a-z]' '[A-Z]' | cat >> "dt"
        center "  +$bar+  " >> "dt"
        ;;
esac
echo >>dt
echo >>dt
echo --$USER >>dt
echo $timestamp >>dt

echo $EDITOR
case $EDITOR in
    *vim|*vi)
        vim +"read dt" +"set wrap" +"set spell" +"startinsert" +"set tw=0" +/^$/ $fname
        ;;
    *nano)
        cat dt | $EDITOR --softwrap $fname
        ;;
    *)
        $EDITOR $fname
        ;;
esac

# remove temporary file
rm dt

if [ -e $fname ] ; then
    # the gpg line assumes your username is in your keyring
    fold -s $fname \
    | gpg -e -r $GPG_NAME  \
    >tmp
    mv tmp $fname
else
    echo Did not create journal entry
fi

# Clean up vim swap files
if [ -e .$day.sw? ] ; then
    rm -v .$day.sw?
fi
