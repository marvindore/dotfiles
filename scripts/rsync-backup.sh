#!/bin/bash

echo "Starting BackUp..."
echo "Select a number based on day of the Month"
echo "Enter: 1, 11, 22, or 99 (stable): "
read day

if [ "$day" -eq "1" ] || [ "$day" -eq "11" ] || [ "$day" -eq "22" ] || [ "$day" -eq "99" ]; then
  if [ "$day" -eq "99" ]; then
    day="stable"
  fi
  sudo rsync -aAXv --delete --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/home/Downloads/*,/lost+found,.ecryptfs,/home/Drives/*,/home/*/.thumbnails/*,/home/*/.cache/mozilla/*,/home/*/.cache/chromium/*,/home/*/.local/share/Trash/*} / /mnt/sda1/backups/month-$day
else
  echo "Invalid input, you must enter 1, 11, 22, or 99"
  exit 1
fi
