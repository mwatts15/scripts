#!/bin/sh

DEFAULT_DEST_DIR="/media/OS"
DEST_DIR="${1:-${DEST_DIR:-$DEFAULT_DEST_DIR}}"
HOME_BACKUP_LOCATION="${DEST_DIR}/${USER}.backup"
WORK_BACKUP_LOCATION="${DEST_DIR}/${USER}-work.backup"
DOCS_BACKUP_LOCATION="${DEST_DIR}/${USER}-docs.backup"
PICS_BACKUP_LOCATION="${DEST_DIR}/${USER}-pics.backup"

rsync --delete -axv --exclude-from="$HOME/home_backup_excludes" $HOME/ "$HOME_BACKUP_LOCATION" 2>rsync-backup-errors >rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out
echo "====================== WORK =======================" |tee -a rsync-backup-errors rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out 
rsync --delete -axv --exclude-from="$HOME/work_backup_excludes" $HOME/work/ "$WORK_BACKUP_LOCATION" 2>>rsync-backup-errors >>rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out
echo "==================== DOCUMENTS ====================" |tee -a rsync-backup-errors rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out 
rsync --delete -axv --exclude-from="$HOME/docs_backup_excludes" $HOME/documents/ "$DOCS_BACKUP_LOCATION" 2>>rsync-backup-errors >>rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out
echo "==================== PICTURES =====================" |tee -a rsync-backup-errors rsync-out
echo "===================================================" |tee -a rsync-backup-errors rsync-out 
rsync --delete -axv --exclude-from="$HOME/pics_backup_excludes" $HOME/pictures/ "$PICS_BACKUP_LOCATION" 2>>rsync-backup-errors >>rsync-out
