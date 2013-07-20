#!/bin/sh

NOTES_DIR="$HOME/notes"
DATE_FILE="$(dirname $NOTES_DIR)/.$(basename $NOTES_DIR)-last_save"
BACKUP_LOCATION=dum-dums.cs.utexas.edu:notes
LOG=$NOTES_DIR-save_log
DATE=`date +%c`

# get the timestamp
MODIFIED_TIME="$(stat -c "%Y" $NOTES_DIR)"
# get the last time we did a back-up
LAST_SAVE="$(cat $DATE_FILE)"
if [ 0$LAST_SAVE -lt 0$MODIFIED_TIME ] ; then
    scp -r $NOTES_DIR $BACKUP_LOCATION
    echo "$MODIFIED_TIME" > "$LAST_SAVE"
    HUMAN_MODTIME="$(date --date=@$MODIFIED_TIME +%c)"
    TIME_DIFF=$(($MODIFIED_TIME - $LAST_SAVE))
    TIME_DIFF=$(date -u --date=@$TIME_DIFF +%H:%M:%S)
    echo "Saved $NOTES_DIR (last modified at $HUMAN_MODTIME) at $DATE. $TIME_DIFF between modification and save." > $LOG
    LAST_SAVE=$modified_time
fi
# back-up if the last time we did a backup is before the timestamp
echo $MODIFIED_TIME
