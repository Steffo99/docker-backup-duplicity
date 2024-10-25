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
	"${DUPLICITY_TARGET_URL}" \
	/mnt
