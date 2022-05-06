# SENPAI ISO builder

Contains the scripts to build a disk image that deploys a SENPAI node based on AlmaLinux 8.5 

The scripts have been tested on **Alma Linux 8.5**.

## Details about the generated image

- The image created is in ISO format. It is bootable on both BIOS and UEFI systems.

- Once inserted in the device, powering the latter on will lead to a 100% interaction-less installation of a SENPAI worker node.

- The image uses the `scap-security-guide` to harden the system to ANSSI-BP-028-HIGH compliance.

- The user, at boot time, has the option to interrupt the installation to instead install a SENPAI manager node.

- The default root password is `root`. The default admin password is `admin`. Those are the two user accounts on the machine.

- When they log in for the first time, their password **must** be changed (enforced by password expiration in post-install)

## How the whole thing works

It would be best to read the script, but to sum it up:

1. The Alma ISO is extracted

2. The GRUB config is overwritten with one that passes as an initrd argument the path to the kickstart file

3. The kickstart files are copied to the root of the image

4. Additional repositories, with extra packages (like SENPAI and OpenSCAP) are copied to the rootof the image as well

5. The ISO is repackaged, and made bootable.

6. When inserted, GRUB will start the installation with the bundled kickstart.

7. The bundled kickstart will install packages from the bundled repositories.

8. In the kickstart post-install sequence, OpenSCAP is called to harden the system.

9. That's all folks !

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
