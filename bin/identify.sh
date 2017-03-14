#!/bin/bash
## identify.sh - Identify a media type (audio, dvd, bluray) and call autorip.sh with correct settings
## Author: Aaron Meier <aaron@bluespeed.org>

# Read configuration
CONFIGFILE="../conf/main.conf"
source $CONFIGFILE

# Export readings from udevadm
udevadm info -q env -n $DEVNAME

# Default type
TYPE=""
if [ "$ID_FS_TYPE" == "udf" ]; then
  # Mount disk for later identifying
  mkdir -p $DISC_MOUNT_DIR
  mount $DEVNAME $DISC_MOUNT_DIR
  if [[ -d $DISC_MOUNT_DIR/VIDEO_TS ]]; then
    echo "Found dvd video disc at $DEVNAME" >> $DISC_LOG
    $TYPE="-dvd"

  elif [[ -d $DISC_MOUNT_DIR/BDMV ]]; then
    echo "Found bluray video disc at $DEVNAME" >> $DISC_LOG
    $TYPE="-bluray"
  umount -lf $DISC_MOUNT_DIR
  fi
elif [ "$ID_CDROM_MEDIA_TRACK_COUNT_AUDIO" > 0 ]; then
  echo "Found audio disc at $DEVNAME" >> $DISC_LOG
  $TYPE="-audio"
fi

# Launching autorip with correct settings
if [ $TYPE != "" ]
  echo "Running autorip with $TYPE" >> $DISC_LOG
  sh autorip.sh $TYPE
else
  echo "$DEVNAME cannot be identified. Maybe this is a data disc?" >> $DISC_LOG
fi
