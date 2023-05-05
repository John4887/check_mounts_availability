#!/bin/bash

script="check_mounts_availability.sh"
version="1.0.0"
author="John Gonzalez"

while getopts ":v" opt; do
  case $opt in
    v)
      echo "$script - $author - $version"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Reading of CIFS and NFS mount points in /etc/fstab (ignoring commented lines)
custom_mounts=$(grep -E 'cifs|nfs' /etc/fstab | grep -v '^#' | awk '{print $2}')

# Variables to store unavailable mount points
unavailable_mounts=""

# Checking the status of the mount points
for mount_point in $custom_mounts; do
    fs_type=$(grep -E "^\S*\s+$mount_point" /etc/fstab | awk '{print $3}')
    if [[ $fs_type == "nfs" ]]; then
        # Checking if an NFS mount point is mounted
        if ! mountpoint -q "$mount_point"; then
            unavailable_mounts+="$mount_point (NFS), "
        fi
    else
        # Checking if a CIFS mount point is mounted and available with read/write
        if ! mountpoint -q "$mount_point" || ! touch "$mount_point"/test_file || ! rm "$mount_point"/test_file; then
            unavailable_mounts+="$mount_point (CIFS), "
        fi
    fi
done

# Displays the result
if [[ -z $unavailable_mounts ]]; then
    echo "OK - All mount points are available."
    exit 0
else
    # Delete the comma and the space at the end of each string
    unavailable_mounts=${unavailable_mounts%, }
    echo "CRITICAL - Unavailable mount points: $unavailable_mounts"
    exit 2
fi
