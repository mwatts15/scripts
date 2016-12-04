#!/bin/bash

TMPS=$(mktemp)
ROOT=${1:-.}
CFG_NAME="$ROOT/.find-duplicates.cfg"

LIMIT=20000
MINSIZE=1M
PATTERNS=("*")
SIZE_FIELD_WIDTH=20

[ -f "$CFG_NAME" ] && . "$CFG_NAME"

gtf(){
    local tmp=$(mktemp)
    echo "$tmp" >> $TMPS
    echo "$tmp"
}

rmtmps(){
    xargs rm -f < $TMPS
    rm $TMPS
}

print_dups () {
    local potential_dups=$1

    sizzle=$(gtf)
    size=0
    while read l ; do
        this_size=${l%%	*}
        if [ \( x"$ssb" != x \) -a \( "$this_size" != "$size" \) ] ; then
            i=0
            while read x ; do
                while read y ; do
                    xf="${x##*	}"
                    yf="${y##*	}"
                    xstat=$(stat -c "%i" "$xf")
                    ystat=$(stat -c "%i" "$yf")
                    if [ $xstat != $ystat ] ; then
                        cmp -s "$xf" "$yf"
                        if [ $? = 0 ] ; then
                            echo "$xf	$yf"
                        fi
                    fi
                done < <(tail -n +$((i+2)) $sizzle)
                i=$((i+1))
            done < $sizzle
            rm $sizzle
            sizzle=$(gtf)
        fi
        echo "$l" >> $sizzle
        size=$this_size
        ssb=1
    done < $potential_dups
}


potential_dups=$(gtf)
files=$(gtf)
basenames=$(gtf)
namedups=$(gtf)
sizes=$(gtf)
sizedups=$(gtf)

fndcache="$ROOT/.find-duplicates.cache"

echo "Finding files..." >&2
if [ -s "$fndcache" ] ; then
    cp "$fndcache" "$files"
else
    find_pattern="-name \"${PATTERNS[0]}\""
    for pat in "${PATTERNS[@]}" ; do 
        find_pattern="$find_pattern -or -name $pat"
    done

    s="find $ROOT ( -size +$MINSIZE -type f ( $find_pattern ) ) -printf %s\t%p\n"
    $s | awk 'BEGIN { FS = "	" } ; { printf "%'$SIZE_FIELD_WIDTH's\t%s\n", $1, $2 }' | head -n "$LIMIT" | tee  "$files" >&2

    cp "$files" "$fndcache"
fi

echo "Finding same-size files..." >&2
sort -k1 -t$'\t' -n < "$files" | uniq -D -w $SIZE_FIELD_WIDTH > $potential_dups

echo "Comparing files ..." >&2
print_dups "$potential_dups"
rmtmps
