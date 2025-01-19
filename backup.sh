#!/bin/sh

set -o pipefail

hostname=$(cat /etc/hostname)

# Get secrets from files
# Insecure, but there's not much I can do about it
# It's duplicity's fault!
export PASSPHRASE=$(cat "${DUPLICITY_PASSPHRASE_FILE}")

echo "Launched in backup mode, performing backup..." >> /dev/stderr

if [ -n "${NTFY}" ]; then
	echo "Sending ntfy backup start notification..." >> /dev/stderr
	curl "${NTFY}" \
		--silent \
		--header "X-Title: Backup started" \
		--data "Duplicity is attempting to perform a backup to **${DUPLICITY_TARGET_URL}**..." \
		--header "X-Priority: min" \
		--header "X-Tags: arrow_heading_up,duplicity,container-${hostname},${NTFY_TAGS}" \
		--header "Content-Type: text/markdown" \
		>/dev/null
fi

echo "Running duplicity..."
duplicity \
	backup \
	--allow-source-mismatch \
	--full-if-older-than "${DUPLICITY_FULL_IF_OLDER_THAN}" \
	--verbosity info \
	/mnt \
	"${DUPLICITY_TARGET_URL}" \
| tee "/var/log/gestalt-amadeus/log.txt"

backup_result=$?

if [ -n "${NTFY}" ]; then
	case "$backup_result" in
		0)
			echo "Sending ntfy backup complete notification..." >> /dev/stderr
			ntfy_message=$(printf "Duplicity has successfully performed a backup to **${DUPLICITY_TARGET_URL}**!\n\n```\n")$(cat "/var/log/gestalt-amadeus/log.txt")$(printf "\n```")
			curl "${NTFY}" \
				--silent \
				--header "X-Title: Backup complete" \
				--data "$ntfy_message" \
				--header "X-Priority: low" \
				--header "X-Tags: white_check_mark,gestalt-amadeus,gestalt-amadeus-backup,container-${hostname},${NTFY_TAGS}" \
				--header "Content-Type: text/markdown" \
				>/dev/null
		;;
		*)
			echo "Sending ntfy backup failed notification..." >> /dev/stderr
			ntfy_message=$(printf "Duplicity failed to perform a backup to **${DUPLICITY_TARGET_URL}**, and exited with status code **${backup_result}**.\n\n```\n")$(cat "/var/log/gestalt-amadeus/log.txt")$(printf "\n```")
			curl "${NTFY}" \
				--silent \
				--header "X-Title: Backup failed" \
				--data "$ntfy_message" \
				--header "X-Priority: max" \
				--header "X-Tags: sos,gestalt-amadeus,gestalt-amadeus-backup,container-${hostname},${NTFY_TAGS}" \
				--header "Content-Type: text/markdown" \
				>/dev/null
		;;
	esac
fi
