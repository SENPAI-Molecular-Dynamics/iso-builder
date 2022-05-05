# SENPAI ISO builder

Contains the scripts to build a disk image that deploys a SENPAI node based on AlmaLinux 8.5 

The scripts have been tested on **Alma Linux 8.5**.

## Requirements

The build process requires `createrepo`, `curl`, `xorriso` and `syslinux` from EPEL:

`# dnf install epel-release && dnf update`

`# dnf install xorriso syslinux createrepo curl`

## Getting sources

Clone the repo and cd into it:

`# git clone https://github.com/SENPAI-Molecular-Dynamics/iso-builder && cd iso-builder`

## Usage

Add execute permissions to the script:

`# chmod +x build.sh`

Call the script from a terminal:

`# ./build.sh`
