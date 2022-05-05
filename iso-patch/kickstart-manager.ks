###
### This kickstart configuration install a SENPAI worker node
###

# Install locally, from CLI
# (it's fast)
cdrom
graphical

# Automatically accept EULA
eula --agreed

# Default basic partitions
# (and setup LVM)
zerombr
ignoredisk --only-use=sda
clearpart --all --initlabel --drives=sda
autopart --type=lvm

# Locale
lang en_US.UTF-8
timezone Etc/UTC

# Enable DHCP, set hostname
# Allow SSH and SENPAI through the firewall (SENPAI uses port 1337)
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=worker.sen
firewall --enable --ssh --port=1337

# User config
rootpw root
user --name=senpai --password=senpai

# Select the following packages for installation
repo --name=senpaimd --baseurl=file:///run/install/sources/mount-0000-cdrom/senpaimd
%packages --excludedocs
@^Infrastructure Server
senpai
%end

# Pre-installation script
%pre --erroronfail
# Well... there's nothing to do (yet)
%end

# Post-installation script
%post --erroronfail
#!/bin/sh
/bin/passwd --expire root
/bin/passwd --expire senpai
%end

# Enable the following services
services --enable=auditd
services --enable=sshd

%anaconda
# Nothing to do here either (yet)
%end
