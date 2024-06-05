#!/bin/sh

case "$MODE" in
	backup)
        echo "Running first backup..."
        /etc/periodic/daily/backup.sh
        echo "Running cron for daily backups..."
        crond -f -l 0
        echo "Cron has exited."
	;;
	restore)
        echo "Restoring from latest backup..."
        /usr/lib/backup-duplicity/restore.sh
        echo "Done."
	;;
	*)
		echo "No such mode." >> /dev/stderr
	;;
esac
