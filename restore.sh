#!/bin/sh

set -o pipefail

# Get secrets from files
# Insecure, but there's not much I can do about it
# It's duplicity's fault!
export PASSPHRASE=$(cat "${DUPLICITY_PASSPHRASE_FILE}")

echo "Launched in restore mode, restoring backup..." >> /dev/stderr
duplicity \
	restore \
	--force \
	--allow-source-mismatch \
	--verbosity info \
	"${DUPLICITY_TARGET_URL}" \
	/mnt \
| tee "/var/log/gestalt-amadeus/log.txt"


ntfy_message=$(printf "Duplicity has successfully restored a backup from **${DUPLICITY_TARGET_URL}**!\n\n```\n")$(cat "/var/log/gestalt-amadeus/log.txt")$(printf "\n```")

curl "${NTFY}" \
	--silent \
	--header "X-Title: Restore complete" \
	--data "$ntfy_message" \
	--header "X-Priority: low" \
	--header "X-Tags: white_check_mark,gestalt-amadeus,gestalt-amadeus-restore,container-${hostname},${NTFY_TAGS}" \
	--header "Content-Type: text/markdown" \
	>/dev/null
