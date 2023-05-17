#!/bin/sh

echo "Running first backup..."
./backup.sh

echo "Running cron for daily backups..."
crond -f -d 5 -l info
