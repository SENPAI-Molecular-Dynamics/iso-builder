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

# Default basic partitions
# (and setup LVM)
zerombr
ignoredisk --only-use=sda
clearpart --all --initlabel --drives=sda
autopart --type=lvm

# Locale
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc

# Enable SELinux
selinux --enforcing

# Enable DHCP, set hostname
# Allow SSH and SENPAI through the firewall (SENPAI uses port 1337)
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=manager.sen
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
aide
senpai-manager
%end

# Post-installation script
%post --erroronfail
/bin/passwd --expire root
/bin/passwd --expire admin
/bin/oscap xccdf eval --remediate --profile %SCAP_PROFILE% --results /home/admin/scap-results.xml /usr/share/xml/scap/ssg/content/ssg-almalinux8-ds.xml
/bin/oscap xccdf generate report /home/admin/scap-results.xml > /home/admin/scap-report.html
/bin/rm /home/admin/scap-results.xml
%end

# Enable the following services
services --enable=sshd
