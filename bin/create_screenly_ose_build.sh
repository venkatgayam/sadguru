#!/bin/bash

ROOT="/mnt/sdcard/screenly-root"
BOOT="/mnt/sdcard/screenly-boot"
SD_DEV=${SD_DEV:=/dev/sdb}
DESTINATION="$HOME/screenly-build"
DATE=$(date +"%Y-%m-%d")

echo -e "Make sure you run\n\tapt-get clean\nbefore making the build"
sudo mkdir -p "$ROOT" "$BOOT" "$DESTINATION"

if ! [ -b "$SD_DEV"  ]; then
    echo "$SD_DEV is not a device. Exiting."
    exit
fi

echo -e "Mounting disk disks"
sudo mount "${SD_DEV}1" "$BOOT"
sudo mount "${SD_DEV}2" "$ROOT"

echo "Cleaning up logfiles..."
for i in \
  "$ROOT/tmp/*" \
  "$ROOT/var/lib/dhcp/*" \
  "$ROOT/home/pi/.screenly/wifi_set" \
  "$ROOT/home/pi/omxplayer.log" \
  "$ROOT/home/pi/.bash_history" \
  "$ROOT/home/pi/.viminfo" \
  "$ROOT/omxplayer*.log" \
  "$ROOT/boot.bak" \
  "$ROOT/lib/modules/3.6.11"+ \
  "$ROOT/lib/modules.bak" \
  "$ROOT/root/.rpi-firmware"; \
  do
  sudo rm -vrf "$i"
done

echo "Cleaning out APT cache..."
sudo find "$ROOT/var/cache/apt/archives" -type f -delete

echo "Removing swap-file (will be created at boot)..."
sudo rm -f "$ROOT/var/swap"

# Adds build date for future references
echo "$DATE" | sudo tee "$ROOT/etc/screenly_build"

# Updates Broadcom firmware
for i in brcmfmac43430-sdio.txt brcmfmac43430-sdio.bin; do
  echo "Fetching $i from upstream..."
  wget -O "$ROOT/lib/firmware/brcm/$i" "https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm80211/brcm/$i"
done

echo "Removing SSH-keys.."
sudo find "$ROOT/etc/ssh/" -type f -iname *pub -delete
sudo find "$ROOT/etc/ssh/" -type f -iname *key -delete

echo "Removing all log-files in /var/log"
sudo find "$ROOT/var/log" -type f -delete

echo "Filling up disks with zeros..."
sudo dd if=/dev/zero of="$ROOT/zeros" bs=1M
sudo rm -f "$ROOT/zeros"

sudo dd if=/dev/zero of="$BOOT/zeros" bs=1M
sudo rm -f "$BOOT/zeros"

echo "Umounting card..."
sudo umount "$ROOT"
sudo umount "$BOOT"

echo "Running fsck (just to be safe)."
sudo fsck -f -v ${SD_DEV}1
sudo fsck -f -v ${SD_DEV}2

echo "Creating image..."
sudo dd if="$SD_DEV" of="$DESTINATION/$DATE-Screenly_OSE_4GB.img"

cd "$DESTINATION"

echo "Creating zip-archive..."
zip -9 "$DATE-Screenly_OSE_4GB.zip" "$DATE-Screenly_OSE_4GB.img"
md5sum "$DATE-Screenly_OSE_4GB.zip" > "$DATE-Screenly_OSE_4GB.zip.md5"

echo "Removing img-file..."
rm -f "$DATE-Screenly_OSE_4GB.img"
