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
export OUT_DIR=$WORK_DIR/BUILDS/"$DEVICE"
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

  local STOP=$(date)
  echo "-- Stop time =$STOP"
  echo "-- Start time=$START"
  echo "-- Now, clone your device trees to the correct locations!"
  exit 0
}

# --- main() ---
BuildStart "$@"
# --- end main() ---
