#!/bin/bash

#
#
# This script is used to pull an official AlmaLinux image,
# extract it, and build back a custom image bundling SENPAI.
# This way, one can deploy SENPAI across many network nodes all at once.
#
# It's like a whole CI pipeline in a single script
# Until I can afford an infrastructure, it's staying this way!
#
#



# Terminal escape codes to color text
TEXT_GREEN='\e[032m'
TEXT_YELLOW='\e[33m'
TEXT_RED='\e[31m'
TEXT_RESET='\e[0m'

# Logs like systemd on startup, it's pretty
TEXT_INFO="[ ${TEXT_YELLOW}INFO${TEXT_RESET} ]"
TEXT_FAIL="[${TEXT_RED}FAILED${TEXT_RESET}]"
TEXT_SUCC="[  ${TEXT_GREEN}OK${TEXT_RESET}  ]"



# Print the banner
echo '   _____ ______ _   _ _____        _____ '
echo '  / ____|  ____| \ | |  __ \ /\   |_   _|'
echo ' | (___ | |__  |  \| | |__) /  \    | |  '
echo '  \___ \|  __| | . ` |  ___/ /\ \   | |  '
echo '  ____) | |____| |\  | |  / ____ \ _| |_ '
echo ' |_____/|______|_| \_|_| /_/    \_\_____|'
echo ' '
echo -e "${TEXT_GREEN}Building script${TEXT_RESET}"
echo "=> Builds a SENPAI installation ISO from AlmaLinux 8.5"
echo "=> AlmaLinux: https://almalinux.org/"
echo ' '



####
#### VARIABLES
####

# Information regarding the upstream AlmaLinux ISO
ALMA_MIRROR="http://mirror.rackspeed.de" #Set it to whichever you want
ALMA_RELEASE="8.5"
ALMA_ARCH="x86_64"
ALMA_FLAVOR="minimal" #Can be either "minimal", "dvd", or "boot"
ALMA_URL="${ALMA_MIRROR}/almalinux/${ALMA_RELEASE}/isos/${ALMA_ARCH}/AlmaLinux-${ALMA_RELEASE}-${ALMA_ARCH}-${ALMA_FLAVOR}.iso"

# Information regarding the local AlmaLinux ISO
ALMA_LOCAL_DIR="./AlmaLinux"
ALMA_LOCAL_NAME="AlmaLinux-${ALMA_RELEASE}-${ALMA_ARCH}-${ALMA_FLAVOR}.iso"
ALMA_LOCAL="${ALMA_LOCAL_DIR}/${ALMA_LOCAL_NAME}"

LOGFILE="./buildlog.txt"         # Where this script will log stuff
TMPDIR=`mktemp -d`               # The temporary work directory
NEW_ISO_ROOT="${TMPDIR}/isoroot" # The root of the new ISO to build. Subdir of TMPDIR
ISO_PATCH_PATH="./iso-patch"     # The content of the directory will be copied to the root of the ISO before building

# Information regarding the ISO patch to apply
PATH_KS_WORKER="kickstart-worker.ks"
PATH_KS_MANAGER="kickstart-manager.ks"

# Information regarding the to-be-built SENPAI ISO
SENPAI_ISO_VERSION="8.5"
SENPAI_ISO_RELEASE="1"
SENPAI_ISO_ARCH="x86_64"
SENPAI_ISO_LABEL="SENPAI"
SENPAI_ISO_NAME="${SENPAI_ISO_LABEL}-${SENPAI_ISO_VERSION}-${SENPAI_ISO_RELEASE}-${SENPAI_ISO_ARCH}.iso"
SENPAI_ISO_DIR="./build"
SENPAI_ISO="${SENPAI_ISO_DIR}/${SENPAI_ISO_NAME}"
SENPAI_SHA="${SENPAI_ISO}.sha256sum"

# Those are the flags used to rebuild the ISO image
MKISOFS_FLAGS="-o ${SENPAI_ISO} \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	--no-emul-boot \
	--boot-load-size 4 \
	--boot-info-table \
	-eltorito-alt-boot \
	-e images/efiboot.img \
	-graft-points EFI/BOOT=${NEW_ISO_ROOT}/EFI/BOOT images/efiboot.img=${NEW_ISO_ROOT}/images/efiboot.img \
	-no-emul-boot \
        -J \
	-R \
	-V ${SENPAI_ISO_LABEL} \
	${NEW_ISO_ROOT}"



####
####
####



# Clear the build log file
echo "===Buildlog===" > ${LOGFILE}



# Check if the local AlmaLinux directory exists
if [ ! -d ${ALMA_LOCAL_DIR} ]; then
	echo -e "${TEXT_INFO} Local AlmaLinux directory doesn't exist: creating ${ALMA_LOCAL_DIR}"
	mkdir ${ALMA_LOCAL_DIR}
fi



# Check if the ISO exists
if [ ! -f ${ALMA_LOCAL} ]; then
	echo -e "${TEXT_INFO} Downloading the upstream AlmaLinux ISO"
	curl -o ${ALMA_LOCAL} ${ALMA_URL} >> ${LOGFILE}
	if [ $? -ne 0 ]; then
		echo -e "${TEXT_FAIL} Failed to download the upstream AlmaLinux ISO"
		rm -rf ${TMPDIR}
		exit 255
	else
		echo -e "${TEXT_SUCC} Downloaded the upstream AlmaLinux ISO"
	fi
else
	echo -e "${TEXT_INFO} Using previously downloaded AlmaLinux ISO"
fi



# Create the new ISO root dir in the tmpdir
mkdir ${NEW_ISO_ROOT}
if [ $? -ne 0 ]; then
        echo -e "${TEXT_FAIL} Failed to create new ISO root directory"
	rm -rf ${TMPDIR}
        exit 255
else
        echo -e "${TEXT_SUCC} Created new ISO root directory"
fi



# Extract the AlmaLinux ISO to the temporary directory
xorriso -osirrox on -indev ${ALMA_LOCAL} -extract / ${NEW_ISO_ROOT} >> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -e "${TEXT_FAIL} Failed to extract AlmaLinux ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -e "${TEXT_SUCC} Extracted the AlmaLinux ISO"
fi



# Patch the ISO
cp -r ${ISO_PATCH_PATH}/* ${NEW_ISO_ROOT}/
if [ $? -ne 0 ]; then
	echo -e "${TEXT_FAIL} Failed to patch the AlmaLinux ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -e "${TEXT_SUCC} Patched the AlmaLinux ISO"
fi



# Customize the patch
sed -i "s/%SENPAI_ISO_LABEL%/${SENPAI_ISO_LABEL}/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%PATH_KS_WORKER%/${PATH_KS_WORKER}/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%PATH_KS_MANAGER%/${PATH_KS_MANAGER}/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%SENPAI_ISO_LABEL%/${SENPAI_ISO_LABEL}/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg
sed -i "s/%PATH_KS_WORKER%/${PATH_KS_WORKER}/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg
sed -i "s/%PATH_KS_MANAGER%/${PATH_KS_MANAGER}/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg



# Check if the build folder exists
if [ ! -d ${SENPAI_ISO_DIR} ]; then
	echo -e "${TEXT_INFO} Build folder doesn't exist. Creating"
        mkdir ${SENPAI_ISO_DIR}
else
	echo -e "${TEXT_INFO} Detected existing build folder. Cleaning up"
	rm -rf ${SENPAI_ISO_DIR}/*
fi



# Rebuild a bootable ISO
mkisofs ${MKISOFS_FLAGS} >> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -e "${TEXT_FAIL} Couldn't build a SENPAI ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -e "${TEXT_SUCC} Built the SENPAI ISO"
fi



# Run isohybrid
isohybrid --uefi ${SENPAI_ISO} >> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -e "${TEXT_FAIL} Couldn't make ISO bootable"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -e "${TEXT_SUCC} Made the ISO bootable"
fi



# Compute the new ISO's checksum
sha256sum ${SENPAI_ISO} > ${SENPAI_SHA}



# We're done! Let's clean up
echo -e "${TEXT_SUCC} Script succeeded. Cleaning up."
rm -rf ${TMPDIR}
echo "===Buildlog===" > ${LOGFILE}
