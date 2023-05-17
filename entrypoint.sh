#!/bin/sh

case "$MODE" in
	backup)
    echo "Running first backup..."
    /usr/lib/backup-duplicity/backup.sh
    echo "Running cron for daily backups..."
    crond -f -d 5 -l info
	;;
	restore)
    echo "Restoring from latest backup..."
    /usr/lib/backup-duplicity/restore.sh
	;;
	*)
		echo "No such mode." >> /dev/stderr
	;;
esac
