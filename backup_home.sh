#!/bin/sh

DEFAULT_DEST_DIR="/media/Seagate Backup Plus Drive/"
DEST_DIR="${1:-${DEST_DIR:-$DEFAULT_DEST_DIR}}"
COLUMNS=80
GLOBAL_EXCLUDES=backup-excludes

backup () {
    name=$1
    source_location=$2
    dry_run=$3

    backup_location="${DEST_DIR}/${USER}-${name}.backup"
    excludes="./${name}_backup_excludes"
    dry_run_args=""

    touch $excludes
    message "${name}" | tee -a rsync-backup-errors rsync-out

    if [ $dry_run ] ; then 
        message "dry run"
        dry_run_args="-n -i"
    fi
    rsync ${dry_run_args} --delete -ax --exclude-from="${GLOBAL_EXCLUDES}" --exclude-from="${excludes}" "${source_location}" "${backup_location}" 2>>rsync-backup-errors >>rsync-out
}

message()
{
     value=${#1}
     printf "%${COLUMNS}s\n"
     if [ $value -lt $COLUMNS ] ; then
       width=$(( (  $COLUMNS + $value ) / 2 ))
       printf "%${width}s\n"  "$1"
     else
        echo "$1"
     fi
     printf "%${COLUMNS}s\n"
}
rm rsync-out rsync-backup-errors
touch "${GLOBAL_EXCLUDES}"

for x in `cat backup.config` ; do
    if [ ! `echo $x | grep -e "^#"` ] ; then
        name=${x%%:*}
        source=${x##*:}
        backup "${name}" "${source}"
    fi
done
cp rsync-out rsync-backup-errors "${DEST_DIR}/"
