#!/bin/bash

DEFAULT_DEST_DIR="/media/Seagate Backup Plus Drive"
DEST_DIR="${DEST_DIR:-$DEFAULT_DEST_DIR}"
BACKUP_CONFIG=backup.config
COLUMNS=80
GLOBAL_EXCLUDES=backup-excludes

backup () {
    name=$1
    source_location=$2
    dry_run=$3

    backup_location="${DEST_DIR}/${USER}-${name}.backup"
    excludes="./${name}_backup_excludes"
    dry_run_args=""
    echo "Backups going to $backup_location"
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

proc_opts ()
{
    while [[ $# > 0 ]]
    do
        key="$1"
        echo $key
        case $key in
            --dry-run)
                echo "Setting DRY_RUN"
                DRY_RUN=TRUE
                ;;
            --config)
                BACKUP_CONFIG=$2
                echo "Setting config file to ${BACKUP_CONFIG}"
                shift
                ;;
            *)
                echo "Setting DEST_DIR=$key"
                DEST_DIR="${key}"
                ;;
        esac
        shift
    done
}

main ()
{
    rm rsync-out rsync-backup-errors
    touch "${GLOBAL_EXCLUDES}"

    for x in `cat "${BACKUP_CONFIG}"` ; do
        if [ ! `echo $x | grep -e "^#"` ] ; then
            name=${x%%:*}
            src=${x##*:}
            if [ $DRY_RUN ]; then
                echo "Doing dry run";
                backup "${name}" "${src}" TRUE
            else
                backup "${name}" "${src}"
            fi
        fi
    done
    cp rsync-out rsync-backup-errors "${DEST_DIR}/"
}

proc_opts "$@"
main
