#!/bin/sh

case "$MODE" in
	backup)
    echo "Running first backup..."
    ./backup.sh
    echo "Running cron for daily backups..."
    crond -f -d 5 -l info
	;;
	restore)
    echo "Restoring from latest backup..."
    ./restore.sh
	;;
	*)
		echo "No such mode." >> /dev/stderr
	;;
esac
