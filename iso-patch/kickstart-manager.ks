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
part    swap --ondisk=sda --size=8192
part    pv.01 --size=1 --ondisk=sda --grow
volgroup vg_root pv.01
logvol  /               --vgname=vg_root --size=8192 --name=lv_root
logvol  /home           --vgname=vg_root --size=8192 --name=lv_home
logvol  /tmp            --vgname=vg_root --size=8192 --name=lv_tmp
logvol  /usr            --vgname=vg_root --size=8192 --name=lv_usr
logvol  /var            --vgname=vg_root --size=8192 --name=lv_var
logvol  /var/tmp        --vgname=vg_root --size=8192 --name=lv_var_tmp
logvol  /var/log        --vgname=vg_root --size=8192 --name=lv_var_log
logvol  /var/log/audit  --vgname=vg_root --size=8192 --name=lv_var_log_audit
logvol  /srv            --vgname=vg_root --size=8192 --name=lv_srv
logvol  /opt            --vgname=vg_root --size=1 --grow --name=lv_opt

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
senpai-manager
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
%post --erroronfail
/bin/passwd --expire root
/bin/passwd --expire admin
/bin/oscap xccdf eval --remediate --profile %SCAP_PROFILE% --results /home/admin/scap-results.xml /usr/share/xml/scap/ssg/content/ssg-almalinux8-ds.xml
/bin/oscap xccdf generate report /home/admin/scap-results.xml > /home/admin/scap-report.html
/bin/rm /home/admin/scap-results.xml
%end

# Enable the following services
services --enable=sshd
