#!/usr/bin/env bash

set -euo pipefail

# Ensure the Bitwarden CLI is installed
if ! command -v /opt/homebrew/bin/bw &> /dev/null; then
    printf '\033[0;31mBitwarden CLI is required but not found\033[0m\n' >&2
    printf '\033[0;31mPlease install it by running: brew install bitwarden-cli\033[0m\n' >&2
    exit 1
fi

export BW_SESSION=$(\
    /opt/homebrew/bin/bw login --passwordfile ~/passfile "$(cat ~/passfile | tail -n 1)" 2>/dev/null \
    | grep BW_SESSION= | cut -d= -f2 \
)

/opt/homebrew/bin/bw sync

printf '\033[0;32mSyncing complete, getting item attachedSecrets\033[0m\n'
FILE=$(/opt/homebrew/bin/bw get item attachedSecrets)
FILE_ID=$(jq -r .id <<< "$FILE")
ATTACHMENTS=$(jq -c '.attachments[] | {id, fileName}' <<< "$FILE")

if [ ! -d "$HOME/.ssh" ]; then
    printf '\033[0;32mCreating %s directory\033[0m\n' "$HOME/.ssh"
    mkdir -p "$HOME/.ssh"
fi

# Loop over all attachments and download each one
for attachment in $(jq -c . <<< "$ATTACHMENTS"); do
    attachment_id=$(jq -r .id <<< "$attachment")
    attachment_name=$(jq -r .fileName <<< "$attachment")

    printf '\033[0;32mDownloading attachment %s (ID: %s)\033[0m\n' "$attachment_name" "$attachment_id"

    /opt/homebrew/bin/bw get attachment "$attachment_id" --itemid "$FILE_ID" --output "$HOME/.ssh/$attachment_name"
done

printf '\033[0;32mAll done\033[0m\n'