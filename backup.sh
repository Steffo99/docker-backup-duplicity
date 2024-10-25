#!/bin/sh

set -e

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
		--header "X-Tags: arrow_heading_up,${NTFY_TAGS}" \
		--header "Content-Type: text/markdown"
fi

duplicity \
	backup \
	--allow-source-mismatch \
	--full-if-older-than "${DUPLICITY_FULL_IF_OLDER_THAN}" \
	/mnt \
	"${DUPLICITY_TARGET_URL}"

backup_result=$?

if [ -n "${NTFY}" ]; then
	case "$backup_result" in
		0)
			echo "Sending ntfy backup complete notification..." >> /dev/stderr
			curl "${NTFY}" \
				--silent \
				--header "X-Title: Backup complete" \
				--data "Duplicity has successfully performed a backup to **${DUPLICITY_TARGET_URL}**!" \
				--header "X-Priority: low" \
				--header "X-Tags: white_check_mark,${NTFY_TAGS}" \
				--header "Content-Type: text/markdown"
		;;
		*)
			echo "Sending ntfy backup failed notification..." >> /dev/stderr
			curl "${NTFY}" \
				--silent \
				--header "X-Title: Backup failed" \
				--data "Duplicity failed to perform a backup to **${DUPLICITY_TARGET_URL}**, and exited with status code **${backup_result}**." \
				--header "X-Priority: max" \
				--header "X-Tags: sos,${NTFY_TAGS}" \
				--header "Content-Type: text/markdown"
		;;
	esac
fi
