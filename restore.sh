#!/bin/sh

set -e

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
	/mnt

curl "${NTFY}" \
	--silent \
	--header "X-Title: Restore complete" \
	--data "Duplicity has successfully restored a backup from **${DUPLICITY_TARGET_URL}**!" \
	--header "X-Priority: low" \
	--header "X-Tags: white_check_mark,duplicity,container-${hostname},${NTFY_TAGS}" \
	--header "Content-Type: text/markdown" \
	>/dev/null
