#version=OL8

# Simple kickstart file for Oracle Linux 8.x to create the most basic Vagrant base box
#
# Copyright 2024 Martin Bach
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ONLY TO BE USED TO CREATE A MINIMAL VAGRANT BOX IN THE CONTEXT OF THIS REPOSITORY

# ----------------------- installation settings

text
cdrom

# ----------------------- system settings

# software
repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream
skipx

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --ipv6=auto --activate
network  --hostname=ol8packer

# Root password
rootpw --iscrypted $6$22FQNGFudjDgx9Ss$vkEbaR74hbh8ArfYBoZyFT5QcrMpBN48dhKyFM.bv9ZsIPlbgrP1T86LS7ZB0w7u0M3NgLlveZ/1fRDSx.aNO/

# System services
services --enabled="chronyd"

# System timezone
timezone Etc/UTC --isUtc

# vagrant account
user --name=vagrant --password=$6$22FQNGFudjDgx9Ss$vkEbaR74hbh8ArfYBoZyFT5QcrMpBN48dhKyFM.bv9ZsIPlbgrP1T86LS7ZB0w7u0M3NgLlveZ/1fRDSx.aNO/ --iscrypted
sshkey --username=vagrant "REPLACE_ME_SSHKEY"

# partitioning and boot loader
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
ignoredisk --only-use=sda
autopart --type=lvm
clearpart --none --initlabel

%packages
@^minimal-environment
kexec-tools
openssh-server
openssh-clients
bzip2
unzip
curl
wget
drpm

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post --log=/root/ks-post.log

/bin/echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

%end

reboot