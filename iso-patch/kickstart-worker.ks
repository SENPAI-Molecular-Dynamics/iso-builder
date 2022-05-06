###
### This kickstart configuration install a SENPAI worker node
###

# Install locally, from CLI
# (it's fast)
text
cdrom
bootloader --append="rhgb quiet crashkernel=auto"

# Automatically accept EULA
eula --agreed

# Reboot after install
# Don't go graphical
# Don't start the first-boot setup thing
reboot
skipx
firstboot --disable

# This partitioning is compliant with
# - ANSSI-BP-028-R12
# - ANSSI-BP-028-R43
# - ANSSI-BP-028-R47
zerombr
ignoredisk --only-use=sda
clearpart --all --initlabel --drives=sda
part    /boot           --fstype=ext4 --ondisk=sda --size=512
part    /boot/efi       --fstype=vfat --ondisk=sda --size=512
part  /               --fstype=ext4 --ondisk=sda --size=8192
part  /home           --fstype=ext4 --ondisk=sda --size=1024
part  /tmp            --fstype=ext4 --ondisk=sda --size=102
part  /usr            --fstype=ext4 --ondisk=sda --size=8192
part  /var            --fstype=ext4 --ondisk=sda --size=8192
part  /var/tmp        --fstype=ext4 --ondisk=sda --size=4096
part  /var/log        --fstype=ext4 --ondisk=sda --size=4096
part  /var/log/audit  --fstype=ext4 --ondisk=sda --size=4096
part  /opt            --fstype=ext4 --ondisk=sda --size=1024
part  /srv            --fstype=ext4 --ondisk=sda --size=1 --grow

# Locale
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc

# Enable SELinux
selinux --enforcing

# Enable DHCP, set hostname
# Allow SSH and SENPAI through the firewall (SENPAI uses port 1337)
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=worker.sen
firewall --enabled --ssh --port=1337

# User config
rootpw root
user --name=admin --password=admin --groups=wheel

# Select the following packages for installation
repo --name=senpaimd --baseurl=file:///run/install/sources/mount-0000-cdrom/senpaimd
repo --name=senpai-iso-extra --baseurl=file:///run/install/sources/mount-0000-cdrom/senpai-iso-extra
%packages --excludedocs
@^minimal-environment
@standard
scap-security-guide
senpai
%end

# OpenSCAP 
%addon org_fedora_oscap
    content-type = scap-security-guide
    content-path = %SCAP_CONTENT%
    datastream-id = %SCAP_ID_DATASTREAM%
    xccdf-id = %SCAP_ID_XCCDF%
    profile = %SCAP_PROFILE%
%end

# Post-installation script
%post --erroronfail --log=/home/admin/ks-post.log
/bin/passwd --expire root
/bin/passwd --expire admin
%end

# Enable the following services
services --enable=sshd
