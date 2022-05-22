#!/bin/bash

# Sources
export SOURCE="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
export SOURCE_BRANCH="twrp-11"
export DT_LINK="https://github.com/InfidelRahul/android_device_xiaomi_evergo.git"

# Device
export DEVICE="evergo"
export OEM="xiaomi"
export TARGET="bootimage"
export TWRP_BUILD_TYPE="Unofficial"
export OF_MAINTAINER="@InfidelRahul"
# TWRP
export TW_DEFAULT_LANGUAGE="en"
export LC_ALL="C"
export ALLOW_MISSING_DEPENDENCIES=true
export OF_VIRTUAL_AB_DEVICE=1
export OF_AB_DEVICE=1
export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
export LC_ALL="C"
export OUTPUT="TWRP*.zip"

# Kernel Source
export KERNEL_SOURCE_LINK="https://github.com/InfidelRahul/evergo.git"

# ENV Do Not Change
export WORK_DIR="$HOME/work"
export OUT_DIR="$WORK_DIR/out"
export KERNEL_DIR="kernel/$OEM/$DEVICE"
export DT_DIR="device/$OEM/$DEVICE"
export USE_CCACHE=1
export CCACHE_SIZE="50G"
export CCACHE_DIR="$HOME/work/.ccache"
export J_VAL=j16

# repo init and repo sync
source_sync() {
  cd $WORK_DIR
  echo "-- Initialising the $SOURCE_BRANCH minimal manifest repo ..."
  repo init --depth=1 -u $SOURCE -b $SOURCE_BRANCH
  [ "$?" != "0" ] && {
    abort "-- Failed to initialise the minimal manifest repo. Quitting."
  }
  echo "-- Done."

  echo "-- Syncing the $SOURCE_BRANCH minimal manifest repo ..."
  repo sync -$J_VAL
  [ "$?" != "0" ] && {
    abort "-- Failed to Sync the minimal manifest repo. Quitting."
  }
  echo "-- Done."
}

device_source_sync() {
  echo "-- Cloning the $DEVICE device tree..."
  git clone $DT_LINK --depth=1 --single-branch $DT_DIR
  [ "$?" != "0" ] && {
    abort "-- Failed to initialise the minimal manifest repo. Quitting."
  }
  echo "-- Done."

  if [ "$KERNEL_SOURCE_LINK" != "" ]; then
    echo "-- Cloning the $DEVICE kernel source..."
    git clone $KERNEL_SOURCE_LINK --depth=1 --single-branch $KERNEL_DIR
    [ "$?" != "0" ] && {
      abort "-- Failed to initialise the minimal manifest repo. Quitting."
    }
    echo "-- Done."
  fi

}

# BUILD
build_twrp() {
  cd $WORK_DIR/
  echo "-- Compiling a test build for device \"$DEVICE\". This will take a *VERY* long time ..."
  echo "-- Start compiling: "
  . build/envsetup.sh
  lunch twrp_${DEVICE}-eng || { echo "ERROR: Failed to lunch the target!" && exit 1; }

  if [ -z "$J_VAL" ]; then
    mka -j$(nproc --all) $TARGET || { echo "ERROR: Failed to Build OrangeFox!" && exit 1; }
  elif [ "$J_VAL"="0" ]; then
    mka $TARGET || { echo "ERROR: Failed to Build OrangeFox!" && exit 1; }
  else
    mka -j${J_VAL} $TARGET || { echo "ERROR: Failed to Build OrangeFox!" && exit 1; }
  fi
}

zip_recovery() {
  # Change to the Output Directory
  echo "-- Change to the Output Directory: $OUT_DIR/target/product/${DEVICE} "
  cd $OUT_DIR/target/product/${DEVICE}

  echo "-- Changing Name to twrp.img "
  mv boot.img twrp-${DEVICE}.img || { echo "ERROR: Failed to Rename!" && exit 1; }

  echo "-- Creating Zip file "
  zip -r9 TWRP-${DEVICE}-${TWRP_BUILD_TYPE}.zip *.img || { echo "ERROR: Failed to create ZIP!" && exit 1; }

  echo "-- zip created successfully "
}

upload_recovery() {

  # Display a message
  echo "============================"
  echo "Uploading the Build..."
  echo "============================"

  # Change to the Output Directory
  cd $OUT_DIR/target/product/${DEVICE}

  # Set FILENAME var
  FILENAME=$(echo $OUTPUT)

  # Upload to oshi.at
  if [ -z "$TIMEOUT" ]; then
    TIMEOUT=20160
  fi

  # Upload to WeTransfer
  # NOTE: the current Docker Image, "registry.gitlab.com/sushrut1101/docker:latest", includes the 'transfer' binary by Default
  transfer wet $FILENAME >link.txt || { echo "ERROR: Failed to Upload the Build!" && exit 1; }

  # Mirror to oshi.at
  curl -T $FILENAME https://oshi.at/${FILENAME}/${OUTPUT} >mirror.txt || { echo "WARNING: Failed to Mirror the Build!"; }

  DL_LINK=$(cat link.txt | grep Download | cut -d\  -f3)
  MIRROR_LINK=$(cat mirror.txt | grep Download | cut -d\  -f1)

  # Show the Download Link
  echo "=============================================="
  echo "Download Link: ${DL_LINK}" || { echo "ERROR: Failed to Upload the Build!"; }
  echo "Mirror: ${MIRROR_LINK}" || { echo "WARNING: Failed to Mirror the Build!"; }
  echo "=============================================="

  DATE_L=$(date +%d\ %B\ %Y)
  DATE_S=$(date +"%T")

  # Exit
  exit 0
}

# HOME DIR
# do all the work!
BuildStart() {
  local START=$(date)
  mkdir -p $WORK_DIR

  source_sync
  device_source_sync
  build_twrp
  zip_recovery
  upload_recovery

  local STOP=$(date)
  echo "-- Stop time =$STOP"
  echo "-- Start time=$START"
  exit 0
}

# --- main() ---
BuildStart "$@"
# --- end main() ---
