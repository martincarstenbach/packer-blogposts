#version=OL9

# Simple kickstart file for Oracle Linux 9.x to create the most basic Vagrant base box
#
# Copyright 2023 Martin Bach
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
repo --name="AppStream" --baseurl=file:///run/install/sources/mount-0000-cdrom/AppStream
skipx

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --ipv6=auto --activate
network  --hostname=ol9packer

# Root password
rootpw --iscrypted $6$wz0w1cWqtJbHDBGV$sxI3YgJCWxXUdf1kUZd8KneBCK2iwW1Fh/SdeLWJ.gBTNDrJrex2/ANoR7OQ3jGJcetT1yXaW.fGAhRFgn7cd1

# System services
services --enabled="chronyd"

# System timezone
timezone Etc/UTC --isUtc

# vagrant account
user --name=vagrant --password=$6$0tKbDlH3oWCofl1G$cblMfvUCop9TCgTAKfQZYM4l3ZLahzrirsXrFW6Hv56GFLXKp5kQ5TqEi6fkWJ5HkvAo3gw8tdP6ZJ3xaD0Km/ --iscrypted --gecos="vagrant"

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

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post --log=/root/ks-post.log

/bin/echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

%end

reboot