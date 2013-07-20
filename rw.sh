#!/bin/bash
DISPLAY=:0
export DISPLAY

WP_CONFIG=$HOME/.rwcfg

WP_DIR=$HOME/pictures/wp
WP_PATH=.
WP_CMD="feh --bg-fill"

[ -f $WP_CONFIG ] && . $WP_CONFIG

WP_CACHE="$WP_DIR/.nm_ims"
WP_RECACHE=FALSE
WP_TITLE_OVERLAY=${TITLE_OVERLAY:-1}
WP_WIDTH=${WIDTH:-1366}
WP_HEIGHT=${HEIGHT:-768}

cd $WP_DIR

STORED_FILES="$WP_DIR/.files"

get_wp_sized_pics ()
{
    my_files=$1
    while read f; do
        WH=( `identify -format "%W %H" "$f"` )
        sized=$((WH[0] >= WIDTH && WH[1] >= HEIGHT))
        if [ $sized -eq 1 ] ; then
            echo "$f"
        fi
    done < $my_files
}

WP_TMP=/tmp/rwtmp-$$
IFS=':'
tail -n +2 $WP_CACHE > $WP_TMP; mv $WP_TMP $WP_CACHE
echo -n >$WP_TMP
for dir in $WP_PATH; do
    find $dir -maxdepth 1 \( -iname "*.jpg" -or -iname "*.png" \) -type f -printf "%p\n" >>$WP_TMP
done
unset IFS

if [ ! -e $WP_CACHE ] ; then echo 0 >$WP_CACHE ; fi

diff $WP_TMP $STORED_FILES
status=$?
[ x$WP_RECACHE = xFALSE ] && status=0
if [ $status -ne 0 -o ! -s $WP_CACHE ] ; then
    get_wp_sized_pics $WP_TMP > $WP_CACHE
    shuf $WP_CACHE -o $WP_CACHE # works because shuf is nice :)
    mv $WP_TMP $STORED_FILES
else
    rm $WP_TMP
fi

wpfile="`head -n 1 $WP_CACHE`"

if [ x$WP_TITLE_OVERLAY == xTRUE ] ; then
    label="`echo $wpfile | egrep -oe '[^/]+$' | tr -d '\\\\' | head -c-5`"
    convert "$wpfile" -compose difference -strokewidth 2 -stroke "rgba(10,40,120,100)" -fill "rgba(255,255,255,100)" -gravity center -pointsize 105 -annotate 0x0+300 "$label" $HOME/.rwbg
else
    cp "$wpfile" $HOME/.rwbg
fi

$WP_CMD $HOME/.rwbg
