#!/bin/bash

# Prompt the user for the pool name
read -p "Enter the pool name: " POOLNAME

# Define datasets and directories
CONFIG_DATASETS=("prowlarr" "radarr" "sonarr" "jellyseerr" "recyclarr" "bazarr" "tdarr" "jellyfin" "sabnzbd" "dozzle")
TDARR_SUBDIRS=("server" "logs" "transcode_cache")
MEDIA_SUBDIRECTORIES=("movies" "tv" "downloads")
DOCKER_COMPOSE_PATH="/mnt/$POOLNAME/docker"
QBITTORRENT_WIREGUARD_DIR="/mnt/$POOLNAME/configs/qbittorrent/wireguard"

# Function to create and set up a dataset
create_dataset() {
    local dataset_name="$1"
    local dataset_path="$POOLNAME/$dataset_name"
    local mountpoint="/mnt/$dataset_path"

    if ! zfs list "$dataset_path" >/dev/null 2>&1; then
        echo "Creating dataset: $dataset_path"
        zfs create "$dataset_path"
    fi

    # Ensure dataset is mounted
    if ! mountpoint -q "$mountpoint"; then
        echo "Mounting dataset: $dataset_path"
        zfs mount "$dataset_path"
    fi

    # Verify mount exists before applying permissions
    if [ -d "$mountpoint" ]; then
        chown root:apps "$mountpoint"
        chmod 770 "$mountpoint"
    else
        echo "⚠️ Warning: $mountpoint does not exist after mounting. Check dataset status."
    fi
}

# Function to create a directory if it doesn't exist
create_directory() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        chown root:apps "$dir_path"
        chmod 770 "$dir_path"
    else
        echo "Directory already exists: $dir_path, skipping..."
    fi
}

# Create the "configs" dataset (parent)
create_dataset "configs"

# Create the config datasets
for dataset in "${CONFIG_DATASETS[@]}"; do
    create_dataset "configs/$dataset"
done

# Create the "media" dataset (instead of a directory)
create_dataset "media"

# Create subdirectories inside the media dataset
for subdir in "${MEDIA_SUBDIRECTORIES[@]}"; do
    create_directory "/mnt/$POOLNAME/media/$subdir"
done

# Ensure Tdarr subdirectories exist (only if tdarr dataset is properly mounted)
TDARR_MOUNTPOINT="/mnt/$POOLNAME/configs/tdarr"
if mountpoint -q "$TDARR_MOUNTPOINT"; then
    for subdir in "${TDARR_SUBDIRS[@]}"; do
        create_directory "$TDARR_MOUNTPOINT/$subdir"
    done
else
    echo "⚠️ Skipping tdarr subdirectory creation; dataset is not mounted."
fi

