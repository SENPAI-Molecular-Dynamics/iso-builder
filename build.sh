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

# Temporary directory to work in
TMPDIR=""

####
####
####



# Check if the local AlmaLinux directory exists
if [ ! -d ${ALMA_LOCAL_DIR} ]; then
	echo -e "${TEXT_INFO} Local AlmaLinux directory doesn't exist: creating ${ALMA_LOCAL_DIR}"
	mkdir ${ALMA_LOCAL_DIR}
fi



# Check if the ISO exists
if [ ! -f ${ALMA_LOCAL} ]; then
	echo -e "${TEXT_INFO} Downloading the upstream AlmaLinux ISO"
	curl -o ${ALMA_LOCAL} ${ALMA_URL}
	if [ $? -ne 0 ]; then
		echo -e "${TEXT_FAIL} Failed to download the upstream AlmaLinux ISO"
		exit 255
	else
		echo -e "${TEXT_SUCC} Downloaded the upstream AlmaLinux ISO"
	fi
else
	echo -e "${TEXT_INFO} Using previously downloaded AlmaLinux ISO"
fi



# Create a temporary directory to work in
TMPDIR=`mktemp -d`
if [ $? -ne 0 ]; then
	echo -e "${TEXT_FAIL} Failed to create temporary directory"
	exit 255
fi
